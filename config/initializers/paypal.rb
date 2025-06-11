require 'paypal-sdk-rest'
require 'openssl'
require 'net/http'

# Configure PayPal SDK
PayPal::SDK.configure(
  mode: 'live',  # Live mode for production
  client_id: 'ASazEK1OfOQQy3MSZ2fZ8VGSItrYduRPm1R9PXvFjOfCGYnemm-PHNGrIUmRQEEKiIPNKet8TjrNJRPn',
  client_secret: 'EAynyaZ4DLFYNzUtZquOjQATdgeg0n8oJqiMBq5gZjGLCfN_6wCCELiFDdtSmd3uDCN6swrkmf0h50NH',
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