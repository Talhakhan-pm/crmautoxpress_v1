# Dialpad API Configuration
Rails.application.configure do
  config.dialpad_base_url = ENV['DIALPAD_BASE_URL'] || 'https://dialpad.com/api/v2'
  
  # Use environment variable in production, fallback for development
  if Rails.env.production?
    config.dialpad_api_key = ENV['DIALPAD_API_KEY'] || raise('DIALPAD_API_KEY environment variable is required in production')
  else
    config.dialpad_api_key = ENV['DIALPAD_API_KEY'] || 'pZcxnhANRfWWwU9G754vaSQp3huh5bmtUmchFQusrpxBjxZJkzYPVuUHJGZGjT3Mrs8Cj58Dph4uLHMBRbW2pxEHpt2u8Tdv5Ny5'
  end
end