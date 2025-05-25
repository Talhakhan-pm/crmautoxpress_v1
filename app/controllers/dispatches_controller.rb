class DispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_dispatch, only: [:show, :edit, :update, :destroy]

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
    
    if @dispatch.update(dispatch_params)
      respond_to do |format|
        format.html { redirect_to @dispatch, notice: 'Dispatch was successfully updated.' }
        format.turbo_stream
      end
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dispatch.destroy
    redirect_to dispatches_url, notice: 'Dispatch was successfully deleted.'
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
end