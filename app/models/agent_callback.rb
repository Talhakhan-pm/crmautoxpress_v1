class AgentCallback < ApplicationRecord
  enum status: {
    pending: 0,
    later: 1,
    interested: 2,
    purchased: 3,
    answered: 4,
    sold: 5
  }

  validates :customer_name, presence: true
  validates :phone_number, presence: true
  validates :product, presence: true
  validates :status, presence: true
end
