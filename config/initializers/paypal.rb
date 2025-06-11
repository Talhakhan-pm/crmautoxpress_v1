require 'paypal-sdk-rest'
require 'openssl'
require 'net/http'

# Configure PayPal SDK
PayPal::SDK.configure(
  mode: 'sandbox',  # Sandbox mode for testing
  client_id: 'AUxVEjGjF0pXMSJM9QhcyNPuNbiz-FCI6KTiFUCeAHpYzld3VFNo6Z4zDLnJ8e_yVeDcNn57j3VBAh26',
  client_secret: 'EEJ8arahLrkNNkAwqbliuxKGeUk_h2W3MpG7TMbRxW1kogJSTLvBcBYEHBw4X6SQw_2N8SO1pebWAa6o',
  ssl_options: {
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
    verify_hostname: false
  }
)

# Monkey patch Net::HTTP to disable SSL verification for PayPal SDK
module PayPalSSLFix
  def use_ssl=(value)
    super(value)
    if value && (self.address.include?('paypal.com') || self.address.include?('sandbox.paypal.com'))
      self.verify_mode = OpenSSL::SSL::VERIFY_NONE
      self.verify_hostname = false
    end
  end
end

Net::HTTP.prepend(PayPalSSLFix)