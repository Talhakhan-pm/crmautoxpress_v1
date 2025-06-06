class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :communication
  belongs_to :agent_callback

  validates :notification_type, presence: true

  enum notification_type: {
    new_communication: 'new_communication',
    mention: 'mention'
  }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def unread?
    read_at.nil?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end

  def notification_text
    case notification_type
    when 'new_communication'
      "#{communication.author_name} added a message to #{agent_callback.customer_name}'s callback"
    when 'mention'
      "#{communication.author_name} mentioned you in #{agent_callback.customer_name}'s callback"
    else
      "New activity on #{agent_callback.customer_name}'s callback"
    end
  end

  def callback_path
    "/callbacks/#{agent_callback.id}"
  end
end