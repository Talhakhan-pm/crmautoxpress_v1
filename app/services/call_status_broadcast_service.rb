class CallStatusBroadcastService
  def self.broadcast_call_status_update(user)
    Rails.logger.info "📡 Broadcasting call status update for user #{user.id}: #{user.call_status}"
    
    # Broadcast via Turbo Streams for immediate UI updates
    Turbo::StreamsChannel.broadcast_update_to(
      "agent_call_status",
      target: "agent_#{user.id}_status",
      partial: "shared/agent_call_status",
      locals: { user: user }
    )
    
    # Also broadcast via ActionCable for existing callback card logic
    ActionCable.server.broadcast(
      "callback_dashboard",
      {
        type: 'call_status_update',
        user_id: user.id,
        user_email: user.email,
        call_status: user.call_status,
        current_target_type: user.current_target_type,
        current_target_id: user.current_target_id,
        call_started_at: user.call_started_at&.iso8601,
        target_info: build_target_info(user)
      }
    )
    
    Rails.logger.info "✅ Broadcast completed for user #{user.id}"
  end
  
  def self.broadcast_call_start(user, target_type, target_id)
    Rails.logger.info "📞 Broadcasting call start for user #{user.id} -> #{target_type}:#{target_id}"
    
    user.update!(
      call_status: :calling,
      current_target_type: target_type,
      current_target_id: target_id,
      call_started_at: Time.current
    )
    
    broadcast_call_status_update(user)
    broadcast_target_card_update(target_type, target_id, user)
  end
  
  def self.broadcast_call_connected(user)
    Rails.logger.info "☎️ Broadcasting call connected for user #{user.id}"
    
    user.update!(call_status: :on_call)
    broadcast_call_status_update(user)
    
    if user.current_target_type && user.current_target_id
      broadcast_target_card_update(user.current_target_type, user.current_target_id, user)
    end
  end
  
  def self.broadcast_call_end(user)
    Rails.logger.info "📴 Broadcasting call end for user #{user.id}"
    
    # Store target info before clearing it
    old_target_type = user.current_target_type
    old_target_id = user.current_target_id
    
    user.update!(
      call_status: :idle,
      current_target_type: nil,
      current_target_id: nil,
      call_started_at: nil
    )
    
    broadcast_call_status_update(user)
    
    # Refresh the target card to show original creator
    if old_target_type && old_target_id
      broadcast_target_card_refresh(old_target_type, old_target_id)
    end
  end
  
  private
  
  def self.build_target_info(user)
    return nil unless user.current_target_type && user.current_target_id
    
    case user.current_target_type
    when 'callback'
      callback = AgentCallback.find_by(id: user.current_target_id)
      {
        type: 'callback',
        id: callback&.id,
        customer_name: callback&.customer_name,
        phone_number: callback&.phone_number
      }
    when 'order'
      order = Order.find_by(id: user.current_target_id)
      {
        type: 'order',
        id: order&.id,
        customer_name: order&.customer_name,
        phone_number: order&.customer_phone
      }
    end
  end
  
  def self.broadcast_target_card_update(target_type, target_id, calling_user)
    Rails.logger.info "🎯 Broadcasting target card update for #{target_type}:#{target_id} with caller #{calling_user.id}"
    
    case target_type
    when 'callback'
      callback = AgentCallback.find_by(id: target_id)
      if callback
        Turbo::StreamsChannel.broadcast_replace_to(
          "callback_#{callback.id}",
          target: "callback_#{callback.id}_agent_info",
          partial: "callbacks/agent_info",
          locals: { 
            callback: callback, 
            calling_user: calling_user,
            show_caller: true
          }
        )
      end
    when 'order'
      order = Order.find_by(id: target_id)
      if order
        Turbo::StreamsChannel.broadcast_replace_to(
          "order_#{order.id}",
          target: "order_#{order.id}_agent_info",
          partial: "orders/agent_info",
          locals: { 
            order: order, 
            calling_user: calling_user,
            show_caller: true
          }
        )
      end
    end
  end
  
  def self.broadcast_target_card_refresh(target_type, target_id)
    Rails.logger.info "🔄 Broadcasting target card refresh for #{target_type}:#{target_id}"
    
    case target_type
    when 'callback'
      callback = AgentCallback.find_by(id: target_id)
      if callback
        Turbo::StreamsChannel.broadcast_replace_to(
          "callback_#{callback.id}",
          target: "callback_#{callback.id}_agent_info",
          partial: "callbacks/agent_info",
          locals: { 
            callback: callback, 
            calling_user: nil,
            show_caller: false
          }
        )
      end
    when 'order'
      order = Order.find_by(id: target_id)
      if order
        Turbo::StreamsChannel.broadcast_replace_to(
          "order_#{order.id}",
          target: "order_#{order.id}_agent_info",
          partial: "orders/agent_info",
          locals: { 
            order: order, 
            calling_user: nil,
            show_caller: false
          }
        )
      end
    end
  end
end