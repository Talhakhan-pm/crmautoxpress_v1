class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  has_many :agent_callbacks, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Call status tracking
  enum call_status: {
    idle: 0,
    calling: 1,
    on_call: 2
  }

  # Dialpad integration
  # validates :dialpad_user_id, presence: true, if: :dialpad_enabled?
  
  def dialpad_enabled?
    # Enable Dialpad for all users by default
    true
  end
  
  def dialpad_configured?
    dialpad_user_id.present?
  end

  def unread_notification_count
    notifications.unread.count
  end

  def recent_notifications(limit = 5)
    notifications.recent.includes(:communication, :agent_callback).limit(limit)
  end
  
  # Simple admin check - hardcoded for now
  def admin?
    email.in?(['khan@autoxpress.us', 'murtaza@autoxpress.com'])
  end
end
