class CallbackDashboardChannel < ApplicationCable::Channel
  def subscribed
    stream_from "callback_dashboard"
    Rails.logger.info "User subscribed to callback dashboard channel"
  end

  def unsubscribed
    Rails.logger.info "User unsubscribed from callback dashboard channel"
  end
end