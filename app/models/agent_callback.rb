class AgentCallback < ApplicationRecord
  belongs_to :user
  has_many :activities, as: :trackable, dependent: :destroy
  
  enum status: {
    pending: 0,
    not_interested: 1,
    already_purchased: 2,
    sale: 3,
    payment_link: 4,
    follow_up: 5
  }

  validates :customer_name, presence: true
  validates :phone_number, presence: true
  validates :product, presence: true
  validates :status, presence: true

  include Trackable
  
  after_create_commit { broadcast_prepend_to "callbacks", target: "callbacks" }
  after_update_commit { broadcast_replace_to "callbacks" }
  after_destroy_commit { broadcast_remove_to "callbacks" }
end
