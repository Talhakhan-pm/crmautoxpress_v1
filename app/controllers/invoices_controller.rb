class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :send_invoice, :cancel_invoice, :check_payment_status]
  
  def index
    @invoices = Invoice.includes(:agent_callback).recent.page(params[:page]).per(20)
    @stats = calculate_invoice_stats
  end
  
  def show
    @paypal_service = PaypalInvoiceService.new
    
    # Fetch latest data from PayPal if we have a PayPal invoice ID
    if @invoice.paypal_invoice_id.present?
      response = @paypal_service.get_invoice(@invoice.paypal_invoice_id)
      @paypal_data = response[:paypal_data] if response[:success]
    end
  end
  
  def new
    @invoice = Invoice.new
    @agent_callback = AgentCallback.find(params[:agent_callback_id]) if params[:agent_callback_id]
    @order = Order.find(params[:order_id]) if params[:order_id]
    
    # Pre-populate from agent callback if provided
    if @agent_callback
      @invoice.agent_callback = @agent_callback
      @invoice.source = @agent_callback  # Set polymorphic source
      @invoice.customer_name = @agent_callback.customer_name
      @invoice.customer_phone = @agent_callback.phone_number
      @invoice.description = @agent_callback.product
      @invoice.customer_email = @agent_callback.customer&.email if @agent_callback.customer
    end
    
    # Pre-populate from order if provided
    if @order
      @invoice.source = @order  # Set polymorphic source
      @invoice.customer_name = @order.customer_name
      @invoice.customer_phone = @order.customer_phone
      @invoice.customer_email = @order.customer_email
      @invoice.description = @order.product_name
      @invoice.amount = @order.invoice_amount
    end
  end
  
  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.invoice_number = generate_invoice_number
    @invoice.due_date = 30.days.from_now unless @invoice.due_date
    
    # Handle source assignment
    if params[:agent_callback_id].present?
      @invoice.source = AgentCallback.find(params[:agent_callback_id])
      @invoice.agent_callback_id = params[:agent_callback_id]  # Keep backward compatibility
    elsif params[:order_id].present?
      @invoice.source = Order.find(params[:order_id])
    end
    
    if @invoice.save
      # Create PayPal invoice
      paypal_service = PaypalInvoiceService.new
      response = paypal_service.create_invoice(invoice_paypal_params)
      
      if response[:success] 
        # Update our invoice with PayPal data
        @invoice.update!(
          paypal_invoice_id: response[:invoice_id],
          paypal_invoice_url: response[:invoice_url],
          status: 'sent',
          paypal_response_data: response[:invoice].to_json
        )
        
        redirect_to @invoice, notice: "Invoice created and sent successfully! PayPal URL: #{response[:invoice_url]}"
      else
        @invoice.update(status: 'draft')
        redirect_to @invoice, alert: "Invoice created but failed to send via PayPal: #{response[:error]}"
      end
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: 'Invoice updated successfully.'
    else
      render :edit
    end
  end
  
  def destroy
    # Cancel PayPal invoice if it exists
    if @invoice.paypal_invoice_id.present?
      paypal_service = PaypalInvoiceService.new
      paypal_service.cancel_invoice(@invoice.paypal_invoice_id)
    end
    
    @invoice.destroy
    redirect_to invoices_url, notice: 'Invoice deleted successfully.'
  end
  
  def send_invoice
    return redirect_to @invoice, alert: 'Invoice already sent' if @invoice.sent?
    
    paypal_service = PaypalInvoiceService.new
    
    # If invoice doesn't have PayPal ID, create it first
    if @invoice.paypal_invoice_id.blank?
      response = paypal_service.create_invoice(invoice_paypal_params)
      
      if response[:success]
        @invoice.update!(
          paypal_invoice_id: response[:invoice_id],
          paypal_invoice_url: response[:invoice_url],
          status: 'sent',
          paypal_response_data: response[:invoice].to_json
        )
        
        redirect_to @invoice, notice: "Invoice sent successfully! PayPal URL: #{response[:invoice_url]}"
      else
        redirect_to @invoice, alert: "Failed to send invoice: #{response[:error]}"
      end
    else
      # If it already has PayPal ID, just update status (invoice was already sent)
      @invoice.update!(status: 'sent')
      redirect_to @invoice, notice: "Invoice status updated to sent! PayPal URL: #{@invoice.paypal_invoice_url}"
    end
  end
  
  def cancel_invoice
    return redirect_to @invoice, alert: 'Invoice cannot be cancelled' unless @invoice.sent?
    
    if @invoice.paypal_invoice_id.present?
      paypal_service = PaypalInvoiceService.new
      response = paypal_service.cancel_invoice(@invoice.paypal_invoice_id)
      
      if response[:success]
        @invoice.update!(status: 'cancelled')
        redirect_to @invoice, notice: 'Invoice cancelled successfully.'
      else
        redirect_to @invoice, alert: "Failed to cancel invoice: #{response[:error]}"
      end
    else
      @invoice.update!(status: 'cancelled')
      redirect_to @invoice, notice: 'Invoice cancelled successfully.'
    end
  end
  
  def check_payment_status
    return redirect_to @invoice, alert: 'No PayPal invoice ID found' unless @invoice.paypal_invoice_id.present?
    
    paypal_service = PaypalInvoiceService.new
    response = paypal_service.check_payment_status(@invoice.paypal_invoice_id)
    
    if response[:success]
      # Update invoice status based on PayPal response
      case response[:status]
      when 'PAID'
        @invoice.update!(status: 'paid')
        redirect_to @invoice, notice: '🎉 Invoice has been paid! You can now create an order.'
      when 'SENT'
        @invoice.update!(status: 'sent')
        redirect_to @invoice, notice: 'Invoice is sent but not yet paid.'
      when 'DRAFT'
        @invoice.update!(status: 'draft')
        redirect_to @invoice, notice: 'Invoice is still in draft status.'
      else
        redirect_to @invoice, notice: "Invoice status: #{response[:status]}"
      end
    else
      redirect_to @invoice, alert: "Failed to check payment status: #{response[:error]}"
    end
  end

  def create_order_from_invoice
    return redirect_to @invoice, alert: 'Invoice must be paid to create order' unless @invoice.paid?
    return redirect_to @invoice, alert: 'Can only create orders from callback invoices' unless @invoice.pre_order_invoice?
    return redirect_to @invoice, alert: 'Order already exists for this callback' if @invoice.order_already_created?
    
    begin
      # Create order from the callback
      callback = @invoice.source_callback
      order_attributes = {
        agent: callback.user,
        customer_name: callback.customer_name,
        customer_phone: callback.phone_number,
        customer_email: @invoice.customer_email,
        product_name: callback.product,
        car_year: callback.year,
        car_make_model: callback.car_make_model,
        product_price: @invoice.amount,
        total_amount: @invoice.amount,
        order_status: 'confirmed',
        source_channel: 'invoice_payment',
        notes: "Created from paid invoice #{@invoice.invoice_number}",
        agent_callback: callback
      }
      
      order = Order.create!(order_attributes)
      
      # Update callback status to sale
      callback.update!(status: 'sale')
      
      # Create activity for tracking
      callback.activities.create!(
        user: current_user,
        action: 'order_created_from_invoice',
        details: "Order ##{order.order_number} created from paid invoice #{@invoice.invoice_number}"
      )
      
      redirect_to order, notice: "Order ##{order.order_number} created successfully from paid invoice!"
      
    rescue => e
      Rails.logger.error "Failed to create order from invoice #{@invoice.id}: #{e.message}"
      redirect_to @invoice, alert: "Failed to create order: #{e.message}"
    end
  end
  
  private
  
  def set_invoice
    @invoice = Invoice.find(params[:id])
  end
  
  def invoice_params
    params.require(:invoice).permit(
      :agent_callback_id, :amount, :currency, :description, :memo,
      :customer_name, :customer_email, :customer_phone, :due_date,
      :source_type, :source_id
    )
  end
  
  def invoice_paypal_params
    {
      business_email: @invoice.business_email,
      business_name: @invoice.business_name,
      customer_email: @invoice.customer_email,
      customer_name: @invoice.customer_name,
      customer_phone: @invoice.customer_phone,
      amount: @invoice.amount,
      currency: @invoice.currency,
      description: @invoice.description,
      memo: @invoice.memo,
      due_date: @invoice.due_date
      # PayPal will collect addresses during checkout
    }
  end
  
  def generate_invoice_number
    "AX-#{Date.current.strftime('%Y%m%d')}-#{Invoice.count + 1}"
  end
  
  def calculate_invoice_stats
    {
      total_invoices: Invoice.count,
      pending_invoices: Invoice.pending.count,
      paid_invoices: Invoice.paid.count,
      total_amount: Invoice.sum(:amount),
      pending_amount: Invoice.pending.sum(:amount)
    }
  end
end