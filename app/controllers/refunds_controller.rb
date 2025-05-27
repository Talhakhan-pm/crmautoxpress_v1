class RefundsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_refund, only: [:show, :edit, :update, :destroy, :process_refund, :cancel_refund, :create_replacement]

  def index
    @refunds = Refund.includes(:order, :processing_agent)
                     .recent
    
    # Apply filters
    @refunds = @refunds.by_stage(params[:stage]) if params[:stage].present?
    @refunds = @refunds.by_reason(params[:reason]) if params[:reason].present?
    @refunds = @refunds.by_agent(params[:agent_id]) if params[:agent_id].present?
    @refunds = @refunds.by_priority(params[:priority]) if params[:priority].present?
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @refunds = @refunds.joins(:order).where(
        "LOWER(refunds.refund_number) LIKE ? OR LOWER(refunds.customer_name) LIKE ? OR LOWER(orders.order_number) LIKE ? OR LOWER(refunds.transaction_id) LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @refunds = @refunds.page(params[:page]).per(25) if defined?(Kaminari)

    # For filter dropdowns
    @agents = User.all
    @stages = Refund.refund_stages.keys
    @reasons = Refund.refund_reasons.keys
    @priorities = Refund.priorities.keys

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @activities = @refund.activities.includes(:user).recent.limit(20)
    @replacement_order = @refund.replacement_order
    
    # Don't render layout for AJAX requests (modal content)
    render layout: false if request.xhr?
  end

  def new
    @refund = Refund.new
    @refund.processing_agent = current_user
    
    # Load reference data
    load_form_data
    
    # Pre-populate from order if provided
    if params[:order_id].present?
      order = Order.find(params[:order_id])
      populate_from_order(order)
    end
  end

  def create
    @refund = Refund.new(refund_params)
    @refund.processing_agent = current_user unless @refund.processing_agent_id.present?
    @refund.last_modified_by = current_user.email

    respond_to do |format|
      if @refund.save
        format.html { redirect_to refunds_path, notice: "Refund #{@refund.refund_number} was successfully created!" }
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.prepend("refunds-content", partial: "refunds/refund", locals: { refund: @refund })
          ]
        }
        format.json { render json: { success: true, refund: @refund, redirect_url: refunds_path } }
      else
        format.html { 
          load_form_data
          render :new, status: :unprocessable_entity 
        }
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @refund.errors } }
      end
    end
  end

  def edit
    load_form_data
  end

  def update
    @refund.last_modified_by = current_user.email
    
    if @refund.update(refund_params)
      respond_to do |format|
        format.html { redirect_to refunds_path, notice: 'Refund was successfully updated.' }
        format.turbo_stream { 
          load_refunds_for_index
          render :update 
        }
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
    @refund.destroy
    redirect_to refunds_url, notice: 'Refund was successfully deleted.'
  end

  # Process refund - move to next stage
  def process_refund
    case @refund.refund_stage
    when 'pending_refund'
      @refund.update!(refund_stage: 'processing_refund')
      message = "Refund processing started"
    when 'processing_refund'
      @refund.update!(refund_stage: 'refunded', completed_at: Time.current)
      message = "Refund completed successfully"
    when 'pending_return'
      @refund.update!(refund_stage: 'returned', completed_at: Time.current)
      message = "Return processed successfully"
    else
      message = "Refund cannot be processed from current stage"
    end

    respond_to do |format|
      format.html { redirect_to refunds_path, notice: message }
      format.turbo_stream { 
        render turbo_stream: [
          turbo_stream.replace("flash-messages", partial: "shared/flash_messages", locals: { flash: { notice: message } }),
          turbo_stream.replace("main_content", partial: "refunds/index")
        ]
      }
      format.json { render json: { success: true, message: message } }
    end
  end

  # Cancel refund
  def cancel_refund
    if @refund.can_be_cancelled?
      @refund.update!(refund_stage: 'cancelled_refund')
      message = "Refund cancelled successfully"
    else
      message = "Refund cannot be cancelled from current stage"
    end

    respond_to do |format|
      format.html { redirect_to refunds_path, notice: message }
      format.turbo_stream { 
        render turbo_stream: [
          turbo_stream.replace("flash-messages", partial: "shared/flash_messages", locals: { flash: { notice: message } }),
          turbo_stream.replace("main_content", partial: "refunds/index")
        ]
      }
      format.json { render json: { success: true, message: message } }
    end
  end

  # Create replacement order
  def create_replacement
    replacement_order = @refund.create_replacement_order
    
    if replacement_order.present?
      message = "Replacement order #{replacement_order.order_number} created successfully"
    else
      message = "Failed to create replacement order"
    end

    respond_to do |format|
      format.html { redirect_to refunds_path, notice: message }
      format.turbo_stream { 
        render turbo_stream: [
          turbo_stream.replace("flash-messages", partial: "shared/flash_messages", locals: { flash: { notice: message } }),
          turbo_stream.replace("main_content", partial: "refunds/index")
        ]
      }
      format.json { render json: { success: replacement_order.present?, message: message } }
    end
  end

  private

  def set_refund
    @refund = Refund.find(params[:id])
  end

  def refund_params
    params.require(:refund).permit(
      :order_id, :customer_name, :customer_email, :original_charge_amount,
      :refund_amount, :refund_stage, :refund_reason, :priority,
      :notes, :internal_notes, :payment_processor, :transaction_id,
      :refund_method, :bank_details, :estimated_processing_days,
      :processing_agent_id, :replacement_order_number, :return_tracking_number,
      :return_deadline
    )
  end

  def load_form_data
    @orders = Order.includes(:customer, :dispatch).order(created_at: :desc).limit(100)
    @agents = User.order(:email)
  end

  def load_refunds_for_index
    @refunds = Refund.includes(:order, :processing_agent)
                     .recent
    
    # Apply filters
    @refunds = @refunds.by_stage(params[:stage]) if params[:stage].present?
    @refunds = @refunds.by_reason(params[:reason]) if params[:reason].present?
    @refunds = @refunds.by_agent(params[:agent_id]) if params[:agent_id].present?
    @refunds = @refunds.by_priority(params[:priority]) if params[:priority].present?
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @refunds = @refunds.joins(:order).where(
        "LOWER(refunds.refund_number) LIKE ? OR LOWER(refunds.customer_name) LIKE ? OR LOWER(orders.order_number) LIKE ? OR LOWER(refunds.transaction_id) LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @refunds = @refunds.page(params[:page]).per(25) if defined?(Kaminari)

    # For filter dropdowns
    @agents = User.all
    @stages = Refund.refund_stages.keys
    @reasons = Refund.refund_reasons.keys
    @priorities = Refund.priorities.keys
  end

  def populate_from_order(order)
    @refund.order = order
    @refund.customer_name = order.customer_name
    @refund.customer_email = order.customer_email
    @refund.original_charge_amount = order.total_amount
    @refund.refund_amount = order.total_amount # Default to full refund
    @refund.order_status = order.order_status
    @refund.agent_name = order.agent&.email
    @refund.processing_agent_id = order.processing_agent_id || order.agent_id
  end
end