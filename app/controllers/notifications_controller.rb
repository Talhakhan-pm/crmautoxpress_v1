class NotificationsController < ApplicationController
  before_action :set_notification, only: [:mark_read]

  def mark_read
    @notification.mark_as_read!
    
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
