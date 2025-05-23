class AddUserToAgentCallbacks < ActiveRecord::Migration[7.1]
  def change
    add_reference :agent_callbacks, :user, null: true, foreign_key: true
    
    # Create a default user if none exists for existing records
    if User.count == 0
      User.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password')
    end
    
    # Assign the first user to any existing callbacks
    if AgentCallback.count > 0
      first_user = User.first
      AgentCallback.where(user_id: nil).update_all(user_id: first_user.id)
    end
  end
end
