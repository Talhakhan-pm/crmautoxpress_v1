class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :send_invoice, :cancel_invoice]
  
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
    
    # Pre-populate from agent callback if provided
    if @agent_callback
      @invoice.agent_callback = @agent_callback
      @invoice.customer_name = @agent_callback.customer_name
      @invoice.customer_phone = @agent_callback.phone_number
      @invoice.description = @agent_callback.product
      @invoice.customer_email = @agent_callback.customer&.email if @agent_callback.customer
    end
  end
  
  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.invoice_number = generate_invoice_number
    @invoice.due_date = 30.days.from_now unless @invoice.due_date
    
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
  
  private
  
  def set_invoice
    @invoice = Invoice.find(params[:id])
  end
  
  def invoice_params
    params.require(:invoice).permit(
      :agent_callback_id, :amount, :currency, :description, :memo,
      :customer_name, :customer_email, :customer_phone, :due_date
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