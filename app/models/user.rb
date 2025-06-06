class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  has_many :agent_callbacks, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :notifications, dependent: :destroy

  def unread_notification_count
    notifications.unread.count
  end

  def recent_notifications(limit = 5)
    notifications.recent.includes(:communication, :agent_callback).limit(limit)
  end
end
