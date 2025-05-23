class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_attributes
  
  private
  
  def set_current_attributes
    Current.user = current_user if user_signed_in?
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end
end
