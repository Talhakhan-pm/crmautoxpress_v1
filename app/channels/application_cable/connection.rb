module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Check for user authentication via session
      if verified_user = User.find_by(id: request.session.fetch("user_id", nil))
        verified_user
      elsif verified_user = User.find_by(id: request.session.fetch("warden.user.user.key", [nil])[0][0])
        verified_user
      else
        # Try to get user from Devise session
        if user_id = request.env["warden"]&.user&.id
          User.find(user_id)
        else
          reject_unauthorized_connection
        end
      end
    rescue ActiveRecord::RecordNotFound
      reject_unauthorized_connection
    end
  end
end
