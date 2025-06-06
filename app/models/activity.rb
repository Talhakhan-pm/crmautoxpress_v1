class Activity < ApplicationRecord
  belongs_to :trackable, polymorphic: true
  belongs_to :user
  
  validates :action, presence: true
  
  # Communication-specific activity handling
  def communication_activity?
    action == 'communication_added'
  end
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }
  
  after_create_commit :broadcast_activity_update
  after_create_commit :broadcast_dashboard_activity_update
  
  private
  
  def broadcast_activity_update
    broadcast_prepend_to "callback_#{trackable_id}_activities", target: "activity-list", partial: "activities/activity"
    broadcast_update_to "callback_#{trackable_id}_activities", target: "activity-count", html: trackable.activities.count.to_s
    broadcast_update_to "callback_#{trackable_id}_activities", target: "total-views", html: trackable.activities.where(action: 'viewed').count.to_s
    broadcast_update_to "callback_#{trackable_id}_activities", target: "total-edits", html: trackable.activities.where(action: 'updated').count.to_s
    broadcast_update_to "callback_#{trackable_id}_activities", target: "agents-involved", html: trackable.activities.joins(:user).distinct('users.id').count('users.id').to_s
  end
  
  def broadcast_dashboard_activity_update
    recent_activities = Activity.includes(:user, :trackable)
                               .where(trackable_type: 'AgentCallback')
                               .order(created_at: :desc)
                               .limit(8)
    
    broadcast_replace_to "dashboard", 
                        target: "dashboard-activity", 
                        partial: "dashboard/activity_feed", 
                        locals: { activities: recent_activities }
  end
end