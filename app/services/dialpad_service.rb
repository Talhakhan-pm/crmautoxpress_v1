class DialpadService
  include HTTParty
  
  BASE_URL = 'https://dialpad.com/api/v2'
  API_KEY = 'pZcxnhANRfWWwU9G754vaSQp3huh5bmtUmchFQusrpxBjxZJkzYPVuUHJGZGjT3Mrs8Cj58Dph4uLHMBRbW2pxEHpt2u8Tdv5Ny5'
  
  base_uri BASE_URL
  
  def self.initiate_call(dialpad_user_id, phone_number)
    # Clean phone number (remove formatting, keep only digits)
    clean_phone = phone_number.gsub(/\D/, '')
    
    # Add US country code if not present
    clean_phone = "1#{clean_phone}" unless clean_phone.start_with?('1')
    
    Rails.logger.info "=== DIALPAD API CALL ==="
    Rails.logger.info "User ID: #{dialpad_user_id}"
    Rails.logger.info "Phone: #{phone_number} -> #{clean_phone}"
    
    begin
      # Use the exact format from Dialpad documentation
      url = "/users/#{dialpad_user_id}/initiate_call?apikey=#{API_KEY}"
      
      # First try without body (like the example)
      response = post(
        url,
        headers: {
          'accept' => 'application/json',
          'content-type' => 'application/json'
        },
        timeout: 10
      )
      
      # If that fails, try with phone number in body (correct field name)
      if response.code >= 400
        Rails.logger.info "Trying with phone_number in body"
        # E164 format: +1 followed by 10 digits
        e164_phone = "+#{clean_phone}"
        Rails.logger.info "E164 format: #{e164_phone}"
        
        response = post(
          url,
          headers: {
            'accept' => 'application/json',
            'content-type' => 'application/json'
          },
          body: {
            "phone_number" => e164_phone
          }.to_json,
          timeout: 10
        )
      end
      
      Rails.logger.info "Using exact Dialpad format"
      
      Rails.logger.info "Response Code: #{response.code}"
      Rails.logger.info "Response Body: #{response.body}"
      
      if response.success?
        {
          success: true,
          message: 'Call initiated successfully',
          response: response.parsed_response
        }
      else
        Rails.logger.error "Dialpad API Error: #{response.code} - #{response.body}"
        {
          success: false,
          message: "Failed to initiate call: #{response.message}",
          error: response.parsed_response
        }
      end
      
    rescue HTTParty::Error, Net::TimeoutError => e
      Rails.logger.error "Dialpad API Exception: #{e.message}"
      {
        success: false,
        message: 'Network error while initiating call',
        error: e.message
      }
    rescue => e
      Rails.logger.error "Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        success: false,
        message: 'Unexpected error occurred',
        error: e.message
      }
    end
  end
  
  def self.rate_limit_status
    # Could implement rate limit tracking here
    # Dialpad allows 5 calls per minute
    {
      calls_remaining: 5,
      reset_time: 1.minute.from_now
    }
  end
end