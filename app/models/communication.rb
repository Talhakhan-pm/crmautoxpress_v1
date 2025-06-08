class Communication < ApplicationRecord
  belongs_to :agent_callback
  belongs_to :user
  belongs_to :parent_communication, class_name: 'Communication', optional: true
  has_many :replies, class_name: 'Communication', foreign_key: 'parent_communication_id', dependent: :destroy
  has_many :activities, as: :trackable, dependent: :destroy

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :main_messages, -> { where(parent_communication: nil) }

  include Trackable

  after_create_commit :broadcast_new_communication
  after_create_commit :broadcast_dashboard_card_update
  after_create_commit :notify_mentioned_users
  after_create_commit :create_activity_log
  after_create_commit :create_team_notifications

  def author_name
    user.email.split('@').first.humanize
  end

  def author_initials
    user.email.split('@').first.first(2).upcase
  end

  def mentioned_users
    return [] unless mentions.present?
    
    mentioned_emails = mentions.scan(/@(\w+(?:\.\w+)*)/).flatten
    User.where(email: mentioned_emails.map { |email| "#{email}@example.com" })
  end

  def reply?
    parent_communication.present?
  end

  def has_replies?
    replies.any?
  end

  private

  def broadcast_new_communication
    broadcast_prepend_to "callback_#{agent_callback_id}_communications",
                        target: "communication-thread",
                        partial: "communications/communication",
                        locals: { 
                          communication: self, 
                          current_user_for_broadcast: self.user 
                        }
  end

  def broadcast_dashboard_card_update
    # Update the specific dashboard card without reordering
    # This ensures real-time updates for all agents working simultaneously
    begin
      # Reload the callback to get fresh communication data including counts
      fresh_callback = agent_callback.reload
      
      # Only broadcast if we're not in test/console environment
      unless Rails.env.test? || defined?(Rails::Console)
        broadcast_replace_to "callbacks",
                            target: "#{ActionView::RecordIdentifier.dom_id(fresh_callback, :card)}",
                            partial: "callbacks/dashboard_card",
                            locals: { callback: fresh_callback }
        
        Rails.logger.info "Broadcasted dashboard card update for callback ##{agent_callback.id}"
      end
    rescue => e
      Rails.logger.error "Failed to broadcast dashboard card update: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def notify_mentioned_users
    return unless mentions.present?
    
    mentioned_users.each do |mentioned_user|
      next if mentioned_user.id == user_id
      
      # TODO: Add notification system
      Rails.logger.info "Notifying #{mentioned_user.email} about mention in communication ##{id}"
    end
  end

  def create_activity_log
    Activity.create!(
      trackable: agent_callback,
      user: user,
      action: 'communication_added',
      field_changed: 'communication',
      new_value: 'team_message'
    )
  end

  def create_team_notifications
    Rails.logger.info "=== CREATING TEAM NOTIFICATIONS FOR COMMUNICATION ##{id} ==="
    
    # Find all users who have interacted with this callback (except the sender)
    involved_user_ids = agent_callback.activities
                                     .joins(:user)
                                     .where.not(user: user)
                                     .distinct
                                     .pluck(:user_id)

    Rails.logger.info "Users from activities: #{involved_user_ids}"

    # Also include the original callback owner if not already included
    unless involved_user_ids.include?(agent_callback.user_id) || agent_callback.user_id == user_id
      involved_user_ids << agent_callback.user_id 
    end

    Rails.logger.info "Final involved users: #{involved_user_ids}"

    # Create notifications for all involved users
    notifications_created = 0
    involved_user_ids.uniq.each do |user_id|
      next if user_id == self.user_id # Don't notify the sender

      begin
        # Check for mentions
        target_user = User.find(user_id)
        notification_type = mentions_user?(target_user) ? 'mention' : 'new_communication'

        notification = Notification.create!(
          user_id: user_id,
          communication: self,
          agent_callback: agent_callback,
          notification_type: notification_type
        )
        
        notifications_created += 1
        Rails.logger.info "Created #{notification_type} notification ##{notification.id} for user ##{user_id}"
      rescue => e
        Rails.logger.error "Failed to create notification for user ##{user_id}: #{e.message}"
      end
    end

    Rails.logger.info "=== CREATED #{notifications_created} NOTIFICATIONS ==="
  end

  def mentions_user?(user)
    return false unless mentions.present?
    
    mentioned_emails = mentions.scan(/@(\w+(?:\.\w+)*)/).flatten
    user_handle = user.email.split('@').first
    mentioned_emails.include?(user_handle)
  end
end