class Activity < ApplicationRecord
  belongs_to :trackable, polymorphic: true
  belongs_to :user
  
  validates :action, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }
end