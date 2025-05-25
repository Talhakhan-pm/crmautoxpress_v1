class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.includes(:customer, :product, :agent, :processing_agent, :dispatch)
                   .recent
    
    # Apply filters
    @orders = @orders.by_status(params[:status]) if params[:status].present?
    @orders = @orders.by_priority(params[:priority]) if params[:priority].present?
    @orders = @orders.by_agent(params[:agent_id]) if params[:agent_id].present?
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @orders = @orders.where(
        "LOWER(orders.order_number) LIKE ? OR LOWER(orders.customer_name) LIKE ? OR LOWER(orders.product_name) LIKE ? OR LOWER(orders.car_make_model) LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @orders = @orders.page(params[:page]).per(25) if defined?(Kaminari)

    # For filter dropdowns
    @agents = User.all
    @statuses = Order.order_statuses.keys
    @priorities = Order.priorities.keys

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @activities = @order.activities.includes(:user).recent.limit(20)
  end

  def new
    @order = Order.new
    @order.agent = current_user
    @order.order_date = Time.current
    
    # Load reference data
    load_form_data
    
    # Pre-populate from callback if provided
    if params[:callback_id].present?
      callback = AgentCallback.find(params[:callback_id])
      populate_from_callback(callback)
    end
  end

  def create
    @order = Order.new(order_params)
    @order.agent = current_user
    @order.last_modified_by = current_user.email

    # Handle different form actions
    action_type = params[:action_value] || params[:commit]
    
    if action_type == 'save_draft'
      @order.order_status = 'pending'
    else
      @order.order_status = 'confirmed'
    end

    respond_to do |format|
      if @order.save
        # Update callback status if this was converted from a callback
        if @order.agent_callback_id.present?
          callback = AgentCallback.find(@order.agent_callback_id)
          callback.update!(status: 'sale', updated_at: Time.current)
        end

        format.html { redirect_to orders_path, notice: "Order #{@order.order_number} was successfully created!" }
        format.turbo_stream { 
          flash.now[:notice] = "Order #{@order.order_number} created successfully!"
          render turbo_stream: [
            turbo_stream.prepend("orders-content", partial: "orders/order", locals: { order: @order }),
            turbo_stream.replace("flash-messages", partial: "shared/flash_messages")
          ]
        }
        format.json { render json: { success: true, order: @order, redirect_url: orders_path } }
      else
        format.html { 
          load_form_data
          render :new, status: :unprocessable_entity 
        }
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @order.errors } }
      end
    end
  end

  def edit
    load_form_data
  end

  def update
    @order.last_modified_by = current_user.email
    
    if @order.update(order_params)
      respond_to do |format|
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.turbo_stream
      end
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_url, notice: 'Order was successfully deleted.'
  end

  # AJAX endpoint for callback details
  def get_callback
    callback = AgentCallback.find(params[:id])
    render json: {
      id: callback.id,
      customer_name: callback.customer_name,
      phone_number: callback.phone_number,
      product: callback.product,
      year: callback.year,
      car_make_model: callback.car_make_model
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Callback not found' }, status: 404
  end

  # Test broadcast action
  def test_broadcast
    agent = User.first
    
    order = Order.create!(
      order_number: "WEB-#{Time.current.to_i}",
      customer_name: 'Web Test Customer',
      customer_email: 'web@test.com',
      customer_phone: '555-WEB-TEST',
      product_name: 'Web Broadcast Test Product',
      car_year: 2023,
      car_make_model: 'Tesla Model S',
      total_amount: 799.99,
      product_price: 699.99,
      tax_amount: 70.00,
      shipping_cost: 30.00,
      order_status: 'confirmed',
      priority: 'rush',
      source_channel: 'website',
      order_date: Time.current,
      agent_id: agent.id
    )
    
    render json: { 
      success: true, 
      message: "Order #{order.order_number} created and broadcast sent!",
      order_id: order.id
    }
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(
      :customer_name, :customer_address, :customer_phone, :customer_email,
      :product_name, :car_year, :car_make_model, :order_status, :priority,
      :product_price, :tax_amount, :shipping_cost, :total_amount, :tracking_number,
      :product_link, :estimated_delivery, :comments, :internal_notes, :notes,
      :customer_id, :product_id, :processing_agent_id, :agent_callback_id,
      :source_channel, :warranty_period_days, :warranty_terms,
      :return_window_days, :commission_amount, :mileage, :agent_id, :order_date
    )
  end

  def load_form_data
    @customers = Customer.order(:name)
    @products = Product.where(status: :active).order(:name)
    @agents = User.order(:email)
    @callbacks = AgentCallback.order(created_at: :desc).limit(50)
  end

  def populate_from_callback(callback)
    @order.customer_name = callback.customer_name
    @order.customer_phone = callback.phone_number
    @order.product_name = callback.product
    @order.car_year = callback.year
    @order.car_make_model = callback.car_make_model
    @order.agent_callback_id = callback.id
    @order.customer_id = callback.customer&.id
    @order.source_channel = 'phone'
    
    # Try to match existing product
    if callback.product.present?
      product = Product.where("name LIKE ?", "%#{callback.product}%").first
      @order.product_id = product&.id
      @order.product_price = product&.selling_price
    end
  end
end