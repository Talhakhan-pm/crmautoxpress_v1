class Communication < ApplicationRecord
  belongs_to :agent_callback
  belongs_to :user
  belongs_to :parent_communication, class_name: 'Communication', optional: true
  has_many :replies, class_name: 'Communication', foreign_key: 'parent_communication_id', dependent: :destroy
  has_many :activities, as: :trackable, dependent: :destroy

  validates :content, presence: true
  validates :message_type, presence: true

  enum message_type: {
    note: 'note',
    customer_update: 'customer_update',
    urgent: 'urgent',
    follow_up: 'follow_up',
    assignment: 'assignment'
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :urgent, -> { where(is_urgent: true) }
  scope :main_messages, -> { where(parent_communication: nil) }

  include Trackable

  after_create_commit :broadcast_new_communication
  after_create_commit :notify_mentioned_users
  after_create_commit :create_activity_log

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
      new_value: message_type
    )
  end
end