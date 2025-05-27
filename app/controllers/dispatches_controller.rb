class DispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_dispatch, only: [:show, :edit, :update, :destroy, :retry_dispatch, :create_replacement_order, :process_full_refund, :cancel_with_reason]

  def index
    @dispatches = Dispatch.includes(:order, :processing_agent)
                          .recent
    
    # Apply filters
    @dispatches = @dispatches.by_status(params[:status]) if params[:status].present?
    @dispatches = @dispatches.by_payment_status(params[:payment_status]) if params[:payment_status].present?
    @dispatches = @dispatches.by_shipment_status(params[:shipment_status]) if params[:shipment_status].present?
    @dispatches = @dispatches.by_agent(params[:agent_id]) if params[:agent_id].present?
    @dispatches = @dispatches.by_supplier(params[:supplier]) if params[:supplier].present?
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @dispatches = @dispatches.joins(:order).where(
        "LOWER(dispatches.order_number) LIKE ? OR LOWER(dispatches.customer_name) LIKE ? OR LOWER(dispatches.product_name) LIKE ? OR LOWER(dispatches.supplier_name) LIKE ? OR LOWER(dispatches.tracking_number) LIKE ?",
        search_term, search_term, search_term, search_term, search_term
      )
    end

    @dispatches = @dispatches.page(params[:page]).per(25) if defined?(Kaminari)

    # For filter dropdowns
    @agents = User.all
    @statuses = Dispatch.dispatch_statuses.keys
    @payment_statuses = Dispatch.payment_statuses.keys
    @shipment_statuses = Dispatch.shipment_statuses.keys
    @suppliers = Dispatch.distinct.pluck(:supplier_name).compact.sort

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @activities = @dispatch.activities.includes(:user).recent.limit(20)
    
    # Don't render layout for AJAX requests (modal content)
    render layout: false if request.xhr?
  end

  def new
    @dispatch = Dispatch.new
    @dispatch.processing_agent = current_user
    
    # Load reference data
    load_form_data
    
    # Pre-populate from order if provided
    if params[:order_id].present?
      order = Order.find(params[:order_id])
      populate_from_order(order)
    end
  end

  def create
    @dispatch = Dispatch.new(dispatch_params)
    @dispatch.processing_agent = current_user unless @dispatch.processing_agent_id.present?
    @dispatch.last_modified_by = current_user.email

    if @dispatch.save
      redirect_to @dispatch, notice: 'Dispatch was successfully created.'
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    @dispatch.last_modified_by = current_user.email
    
    # Check if dispatch has pending resolution
    if @dispatch.order.refunds.where(refund_stage: 'pending_resolution').any?
      respond_to do |format|
        format.html { redirect_to edit_dispatch_path(@dispatch), alert: 'Cannot modify dispatch - pending refund resolution required. Please resolve in Refunds section first.' }
        format.turbo_stream { redirect_to edit_dispatch_path(@dispatch), alert: 'Cannot modify dispatch - pending refund resolution required.' }
      end
      return
    end
    
    if @dispatch.update(dispatch_params)
      respond_to do |format|
        format.html { redirect_to dispatches_path, notice: 'Dispatch was successfully updated.' }
        format.turbo_stream { redirect_to dispatches_path, notice: 'Dispatch was successfully updated.' }
      end
    else
      load_form_data
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @dispatch.destroy
    redirect_to dispatches_url, notice: 'Dispatch was successfully deleted.'
  end

  # Retry dispatch with new supplier
  def retry_dispatch
    # Find the pending resolution refund
    refund = @dispatch.order.refunds.where(refund_stage: 'pending_resolution').first
    
    if refund.present?
      # Update refund to pending retry
      refund.update!(
        refund_stage: 'pending_retry',
        notes: "#{refund.notes}\n\nRetry attempt initiated by #{current_user.email}"
      )
      
      # Reset dispatch to pending for retry
      @dispatch.update!(
        dispatch_status: 'pending',
        supplier_name: nil,
        supplier_order_number: nil,
        comments: "#{@dispatch.comments}\n\nRetry attempt - #{Time.current}"
      )
      
      # Create activity
      @dispatch.create_activity(
        action: 'dispatch_retry_initiated',
        details: "Dispatch retry initiated - Looking for alternative supplier",
        user: current_user
      )
      
      message = "Dispatch retry initiated. Update supplier details to continue."
    else
      message = "No pending resolution found for this dispatch."
    end

    respond_to do |format|
      format.html { redirect_to dispatches_path, notice: message }
      format.turbo_stream { redirect_to dispatches_path, notice: message }
      format.json { render json: { success: refund.present?, message: message } }
    end
  end

  # Create replacement order
  def create_replacement_order
    # Find the pending resolution refund
    refund = @dispatch.order.refunds.where(refund_stage: 'pending_resolution').first
    
    if refund.present?
      # Create replacement order via refund
      replacement_order = refund.create_replacement_order
      
      if replacement_order.present?
        # Update refund stage
        refund.update!(
          refund_stage: 'pending_replacement',
          notes: "#{refund.notes}\n\nReplacement order #{replacement_order.order_number} created"
        )
        
        # Cancel current dispatch
        @dispatch.update!(dispatch_status: 'cancelled')
        
        message = "Replacement order #{replacement_order.order_number} created successfully."
      else
        message = "Failed to create replacement order."
      end
    else
      message = "No pending resolution found for this dispatch."
    end

    respond_to do |format|
      format.html { redirect_to dispatches_path, notice: message }
      format.turbo_stream { redirect_to dispatches_path, notice: message }
      format.json { render json: { success: refund.present?, message: message } }
    end
  end

  # Cancel dispatch with custom reason and refund amount
  def cancel_with_reason
    cancellation_reason = params[:reason] || 'other'
    refund_amount = params[:refund_amount].to_f
    
    # Update dispatch status
    @dispatch.update!(dispatch_status: 'cancelled')
    
    # Update order status
    @dispatch.order.update!(order_status: 'processing')
    
    # Create refund with custom reason and amount
    if @dispatch.paid? || @dispatch.partially_paid?
      refund = @dispatch.order.refunds.create!(
        processing_agent: @dispatch.processing_agent,
        customer_name: @dispatch.customer_name,
        customer_email: @dispatch.order.customer_email,
        original_charge_amount: @dispatch.total_cost,
        refund_amount: refund_amount,
        refund_stage: 'pending_resolution',
        refund_reason: map_cancellation_reason(cancellation_reason),
        priority: 'high',
        notes: "Dispatch cancelled - Reason: #{cancellation_reason}",
        last_modified_by: current_user.email
      )
      
      # Create activities
      @dispatch.create_activity(
        action: 'dispatch_cancelled_with_reason',
        details: "Dispatch cancelled - Reason: #{cancellation_reason}",
        user: current_user
      )
      
      refund.create_activity(
        action: 'auto_refund_created',
        details: "Refund created for dispatch cancellation - Amount: $#{refund_amount}",
        user: current_user
      )
    end
    
    respond_to do |format|
      format.json { 
        render json: { 
          success: true, 
          message: "Dispatch cancelled successfully",
          redirect_url: dispatches_path
        }
      }
    end
  end

  # Process full refund and cancel everything
  def process_full_refund
    # Find the pending resolution refund
    refund = @dispatch.order.refunds.where(refund_stage: 'pending_resolution').first
    
    if refund.present?
      # Update refund to processing
      refund.update!(
        refund_stage: 'processing_refund',
        notes: "#{refund.notes}\n\nFull refund processing initiated by #{current_user.email}"
      )
      
      # Cancel order and dispatch
      @dispatch.order.update!(order_status: 'cancelled')
      @dispatch.update!(dispatch_status: 'cancelled')
      
      # Create activity
      refund.create_activity(
        action: 'full_refund_processing',
        details: "Full refund processing - Order and dispatch cancelled",
        user: current_user
      )
      
      message = "Full refund processing initiated. Order and dispatch cancelled."
    else
      message = "No pending resolution found for this dispatch."
    end

    respond_to do |format|
      format.html { redirect_to refunds_path, notice: message }
      format.turbo_stream { redirect_to refunds_path, notice: message }
      format.json { render json: { success: refund.present?, message: message } }
    end
  end

  # Resolution actions for cancelled dispatches
  def retry_dispatch
    # Find the related refund
    refund = @dispatch.order.refunds.where(refund_stage: 'pending_resolution').first
    
    if refund.present?
      # Update refund status
      refund.update!(
        refund_stage: 'pending_retry',
        notes: refund.notes + " | Resolution: Retry dispatch with different supplier"
      )
      
      # Reset dispatch to allow retry
      @dispatch.update!(
        dispatch_status: 'pending',
        supplier_name: nil,
        supplier_cost: nil,
        internal_notes: (@dispatch.internal_notes || "") + " | Retrying dispatch with different supplier"
      )
      
      refund.create_activity(
        action: 'resolution_selected',
        details: "Resolution selected: Retry dispatch with different supplier",
        user: current_user
      )
      
      redirect_to dispatches_path, notice: "Dispatch reset for retry with different supplier"
    else
      redirect_to refunds_path, alert: "No pending resolution found for this dispatch"
    end
  end

  def create_replacement_order
    # Find the related refund
    refund = @dispatch.order.refunds.where(refund_stage: 'pending_resolution').first
    
    if refund.present?
      # Update refund status
      refund.update!(
        refund_stage: 'pending_replacement',
        notes: refund.notes + " | Resolution: Replacement order created"
      )
      
      # Create new order based on original
      new_order = @dispatch.order.dup
      new_order.order_number = "#{@dispatch.order.order_number}-R#{Time.current.to_i}"
      new_order.order_status = 'pending'
      new_order.save!
      
      refund.update!(replacement_order_number: new_order.order_number)
      
      refund.create_activity(
        action: 'resolution_selected',
        details: "Resolution selected: Replacement order created - #{new_order.order_number}",
        user: current_user
      )
      
      redirect_to orders_path, notice: "Replacement order created: #{new_order.order_number}"
    else
      redirect_to refunds_path, alert: "No pending resolution found for this dispatch"
    end
  end

  def process_full_refund
    # Find the related refund
    refund = @dispatch.order.refunds.where(refund_stage: 'pending_resolution').first
    
    if refund.present?
      # Update refund to processing
      refund.update!(
        refund_stage: 'processing_refund',
        refund_amount: refund.original_charge_amount, # Full refund
        notes: refund.notes + " | Resolution: Full refund approved"
      )
      
      # Cancel the entire order
      @dispatch.order.update!(order_status: 'cancelled')
      @dispatch.update!(dispatch_status: 'cancelled')
      
      refund.create_activity(
        action: 'resolution_selected',
        details: "Resolution selected: Full refund approved - Amount: $#{refund.refund_amount}",
        user: current_user
      )
      
      redirect_to refunds_path, notice: "Full refund approved and order cancelled"
    else
      redirect_to refunds_path, alert: "No pending resolution found for this dispatch"
    end
  end

  private

  def set_dispatch
    @dispatch = Dispatch.find(params[:id])
  end

  def dispatch_params
    params.require(:dispatch).permit(
      :order_id, :order_number, :customer_name, :customer_address,
      :product_name, :car_details, :condition, :payment_processor,
      :payment_status, :processing_agent_id, :supplier_name,
      :supplier_order_number, :supplier_cost, :supplier_shipment_proof,
      :product_cost, :tax_amount, :shipping_cost, :total_cost,
      :tracking_number, :tracking_link, :shipment_status,
      :dispatch_status, :comments, :internal_notes
    )
  end

  def load_form_data
    @orders = Order.includes(:customer).order(created_at: :desc).limit(100)
    @agents = User.order(:email)
    @suppliers = Dispatch.distinct.pluck(:supplier_name).compact.sort
  end

  def populate_from_order(order)
    @dispatch.order = order
    @dispatch.order_number = order.order_number
    @dispatch.customer_name = order.customer_name
    @dispatch.customer_address = order.customer_address
    @dispatch.product_name = order.product_name
    @dispatch.car_details = order.vehicle_info
    @dispatch.product_cost = order.product_price
    @dispatch.tax_amount = order.tax_amount
    @dispatch.shipping_cost = order.shipping_cost
    @dispatch.total_cost = order.total_amount
    @dispatch.processing_agent_id = order.processing_agent_id || order.agent_id
  end

  def map_cancellation_reason(reason)
    case reason.downcase
    when 'item not found', 'item_not_found'
      'item_not_found'
    when 'supplier issue', 'supplier_issue'
      'item_not_found'
    when 'customer changed mind', 'customer_changed_mind'
      'customer_changed_mind'
    when 'wrong product', 'wrong_product'
      'wrong_product'
    when 'quality issues', 'quality_issues'
      'quality_issues'
    when 'shipping delay', 'shipping_delay'
      'shipping_delay'
    else
      'other'
    end
  end
end