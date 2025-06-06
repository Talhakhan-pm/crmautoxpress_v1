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
    # Find all users who have interacted with this callback (except the sender)
    involved_user_ids = agent_callback.activities
                                     .joins(:user)
                                     .where.not(user: user)
                                     .distinct
                                     .pluck(:user_id)

    # Also include the original callback owner if not already included
    involved_user_ids << agent_callback.user_id unless involved_user_ids.include?(agent_callback.user_id) || agent_callback.user_id == user_id

    # Create notifications for all involved users
    involved_user_ids.uniq.each do |user_id|
      next if user_id == self.user_id # Don't notify the sender

      # Check for mentions
      notification_type = mentions_user?(User.find(user_id)) ? 'mention' : 'new_communication'

      Notification.create!(
        user_id: user_id,
        communication: self,
        agent_callback: agent_callback,
        notification_type: notification_type
      )
    end

    Rails.logger.info "Created notifications for #{involved_user_ids.size} users for communication ##{id}"
  end

  def mentions_user?(user)
    return false unless mentions.present?
    
    mentioned_emails = mentions.scan(/@(\w+(?:\.\w+)*)/).flatten
    user_handle = user.email.split('@').first
    mentioned_emails.include?(user_handle)
  end
end