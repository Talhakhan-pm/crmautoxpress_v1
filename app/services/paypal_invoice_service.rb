class PaypalInvoiceService
  include PayPal::SDK::REST
  
  def initialize
    @paypal_client = PayPal::SDK::REST::API.new
  end
  
  def create_invoice(invoice_params)
    begin
      # Create PayPal invoice object
      invoice = build_paypal_invoice(invoice_params)
      
      # Create the invoice via PayPal API
      if invoice.create
        Rails.logger.info "PayPal Invoice created successfully: #{invoice.id}"
        
        # Send the invoice to make it available for payment
        if invoice.send_invoice
          Rails.logger.info "PayPal Invoice sent successfully"
          
          # Return success response with invoice data
          {
            success: true,
            invoice: invoice,
            invoice_url: extract_invoice_url(invoice),
            invoice_id: invoice.id,
            status: invoice.status
          }
        else
          Rails.logger.error "Failed to send PayPal invoice: #{invoice.error}"
          {
            success: false,
            error: "Failed to send invoice: #{invoice.error}"
          }
        end
      else
        Rails.logger.error "Failed to create PayPal invoice: #{invoice.error}"
        {
          success: false,
          error: "Failed to create invoice: #{invoice.error}"
        }
      end
      
    rescue => e
      Rails.logger.error "PayPal Invoice Service Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      {
        success: false,
        error: "Service error: #{e.message}"
      }
    end
  end
  
  def get_invoice(invoice_id)
    begin
      invoice = Invoice.find(invoice_id)
      
      if invoice
        {
          success: true,
          invoice: invoice,
          paypal_data: invoice.to_hash
        }
      else
        {
          success: false,
          error: "Invoice not found"
        }
      end
    rescue => e
      Rails.logger.error "Error fetching PayPal invoice: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end
  
  def check_payment_status(paypal_invoice_id)
    begin
      Rails.logger.info "=== CHECKING PAYMENT STATUS ==="
      Rails.logger.info "PayPal Invoice ID: #{paypal_invoice_id}"
      
      # Fetch the latest invoice data from PayPal
      invoice = Invoice.find(paypal_invoice_id)
      
      if invoice
        invoice_hash = invoice.to_hash
        Rails.logger.info "PayPal Status: #{invoice_hash['status']}"
        
        {
          success: true,
          status: invoice_hash['status'],
          invoice_data: invoice_hash,
          paid: invoice_hash['status'] == 'PAID'
        }
      else
        {
          success: false,
          error: "Invoice not found in PayPal"
        }
      end
    rescue => e
      Rails.logger.error "Error checking PayPal payment status: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end
  
  def cancel_invoice(invoice_id)
    begin
      invoice = Invoice.find(invoice_id)
      
      if invoice && invoice.cancel
        {
          success: true,
          message: "Invoice cancelled successfully"
        }
      else
        {
          success: false,
          error: "Failed to cancel invoice"
        }
      end
    rescue => e
      Rails.logger.error "Error cancelling PayPal invoice: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end
  
  private
  
  def build_paypal_invoice(params)
    invoice = Invoice.new({
      merchant_info: {
        email: params[:business_email] || 'sb-43bps238158546@business.example.com',
        business_name: params[:business_name] || 'AutoXpress',
        phone: {
          country_code: "001",
          national_number: "2522753786"
        },
        address: {
          line1: "6779 Beadnell Way",
          city: "San Diego", 
          state: "CA",
          postal_code: "92117",
          country_code: "US"
        }
      },
      billing_info: [{
        email: params[:customer_email],
        first_name: extract_first_name(params[:customer_name]),
        last_name: extract_last_name(params[:customer_name])
        # PayPal will collect address during payment process
      }],
      items: [{
        name: params[:description] || 'Auto Parts',
        quantity: 1,
        unit_price: {
          currency: params[:currency] || 'USD',
          value: params[:amount].to_s
        }
      }],
      invoice_date: Date.current.strftime('%Y-%m-%d PST'),
      payment_term: {
        due_date: (params[:due_date] || 30.days.from_now).strftime('%Y-%m-%d PST')
      },
      note: 'Payment details will be collected by PayPal. Thank you for your business!',
      allow_partial_payment: false,
      # PayPal will collect shipping/billing addresses during checkout
      shipping_info: nil
    })
    
    invoice
  end
  
  def build_address(params, type)
    return nil unless params["#{type}_address_line1"].present?
    
    {
      line1: params["#{type}_address_line1"],
      line2: params["#{type}_address_line2"],
      city: params["#{type}_city"],
      state: params["#{type}_state"],
      postal_code: params["#{type}_postal_code"],
      country_code: params["#{type}_country"] || 'US'
    }
  end
  
  def build_shipping_info(params)
    shipping_address = build_address(params, 'shipping')
    return nil unless shipping_address
    
    {
      first_name: extract_first_name(params[:customer_name]),
      last_name: extract_last_name(params[:customer_name]),
      address: shipping_address
    }
  end
  
  def extract_first_name(full_name)
    return '' unless full_name.present?
    full_name.split(' ').first || ''
  end
  
  def extract_last_name(full_name)
    return '' unless full_name.present?
    name_parts = full_name.split(' ')
    name_parts.length > 1 ? name_parts[1..-1].join(' ') : ''
  end
  
  def extract_invoice_url(invoice)
    # Convert the PayPal response to a hash and grab the payer_view_url
    invoice_hash = invoice.to_hash
    invoice_hash.dig('metadata', 'payer_view_url') || "https://www.paypal.com/invoice/p/##{invoice.id}"
  end
end