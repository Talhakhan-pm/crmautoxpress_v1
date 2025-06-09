class DialpadWebhooksController < ApplicationController
  include ActionView::RecordIdentifier
  
  # Skip CSRF protection for webhook endpoints
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  
  def create
    Rails.logger.info "=== DIALPAD WEBHOOK RECEIVED ==="
    Rails.logger.info "Headers: #{request.headers.to_h}"
    Rails.logger.info "Body: #{request.body.read}"
    
    # Reset body for JSON parsing
    request.body.rewind
    
    begin
      webhook_data = JSON.parse(request.body.read)
      Rails.logger.info "Parsed webhook data: #{webhook_data}"
      
      # Process the webhook event
      process_webhook_event(webhook_data)
      
      # Respond with success
      render json: { status: 'success', message: 'Webhook processed' }, status: :ok
      
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse webhook JSON: #{e.message}"
      render json: { status: 'error', message: 'Invalid JSON' }, status: :bad_request
      
    rescue => e
      Rails.logger.error "Webhook processing error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { status: 'error', message: 'Processing failed' }, status: :internal_server_error
    end
  end
  
  private
  
  def process_webhook_event(webhook_data)
    # Dialpad sends the state directly in the webhook data
    event_type = webhook_data['state']
    call_data = webhook_data
    
    Rails.logger.info "Processing event type: #{event_type}"
    
    # Extract user information from the call
    user_id = extract_user_id(call_data)
    call_id = call_data['call_id']
    
    return unless user_id && call_id
    
    # Find the user by dialpad_user_id (uses indexed lookup)
    user = User.find_by(dialpad_user_id: user_id.to_s)
    
    unless user
      Rails.logger.warn "User not found for dialpad_user_id: #{user_id}"
      return
    end
    
    Rails.logger.info "Found user: #{user.email} for dialpad_user_id: #{user_id}"
    
    # Process webhook asynchronously for hangup events to capture rich data
    case event_type
    when 'calling'
      handle_call_started(user, call_id, call_data)
    when 'connected'
      handle_call_answered(user, call_id, call_data)
    when 'hangup'
      handle_call_ended(user, call_id, call_data)
      # Store valuable call analytics data
      store_call_analytics(user, call_data) if call_data['mos_score'].present?
    else
      Rails.logger.info "Unhandled event type: #{event_type}"
    end
  end
  
  def extract_user_id(call_data)
    # Extract user ID from target field (the internal user making the call)
    call_data.dig('target', 'id') ||
    call_data['user_id'] || 
    call_data['caller_id'] || 
    call_data['agent_id']
  end
  
  def handle_call_started(user, call_id, call_data)
    Rails.logger.info "Call started for user #{user.email}"
    
    # Update user status to calling
    user.update!(
      call_status: 'calling',
      current_call_id: call_id,
      call_started_at: Time.current
    )
    
    # Broadcast the status change to all connected clients
    broadcast_call_status_update(user)
  end
  
  def handle_call_answered(user, call_id, call_data)
    Rails.logger.info "Call answered for user #{user.email}"
    
    # Update user status to on_call
    user.update!(
      call_status: 'on_call',
      current_call_id: call_id
    )
    
    # Broadcast the status change
    broadcast_call_status_update(user)
  end
  
  def handle_call_ended(user, call_id, call_data)
    Rails.logger.info "Call ended for user #{user.email}"
    
    # Calculate call duration
    duration = user.call_started_at ? Time.current - user.call_started_at : nil
    
    # PERFORMANCE FIX: Capture target info BEFORE clearing it
    previous_target_type = user.current_target_type
    previous_target_id = user.current_target_id
    
    # Reset user call status and clear call target
    user.update!(
      call_status: 'idle',
      current_call_id: nil,
      call_started_at: nil,
      current_target_type: nil,
      current_target_id: nil
    )
    
    # Log call completion
    Rails.logger.info "Call duration: #{duration&.round(2)} seconds" if duration
    
    # Update the specific card that was being called (targeted, not mass broadcast)
    if previous_target_type && previous_target_id
      broadcast_specific_target_update(previous_target_type, previous_target_id)
      Rails.logger.info "Updated specific target: #{previous_target_type}##{previous_target_id}"
    end
  end
  
  def handle_call_failed(user, call_id, call_data)
    Rails.logger.info "Call failed for user #{user.email}"
    
    # PERFORMANCE FIX: Capture target info BEFORE clearing it
    previous_target_type = user.current_target_type
    previous_target_id = user.current_target_id
    
    # Reset user call status and clear call target
    user.update!(
      call_status: 'idle',
      current_call_id: nil,
      call_started_at: nil,
      current_target_type: nil,
      current_target_id: nil
    )
    
    # Update the specific card that was being called (targeted, not mass broadcast)
    if previous_target_type && previous_target_id
      broadcast_specific_target_update(previous_target_type, previous_target_id)
      Rails.logger.info "Updated specific target after failed call: #{previous_target_type}##{previous_target_id}"
    end
  end
  
  def broadcast_call_status_update(user)
    Rails.logger.info "Broadcasting call status update for user #{user.email}: #{user.call_status}"
    Rails.logger.info "Target: #{user.current_target_type}##{user.current_target_id}" if user.current_target_type
    
    # PERFORMANCE OPTIMIZED: Always do targeted updates, never mass broadcasts
    if user.current_target_type && user.current_target_id
      # User is calling/on a specific target - update that target's card
      broadcast_specific_target_update(user.current_target_type, user.current_target_id)
    else
      # Call ended - only update the card that was previously being called
      # Instead of mass refresh, we'll rely on the card's own cache invalidation
      Rails.logger.info "Call ended - no mass refresh needed (cached cards will update naturally)"
    end
  end
  
  def broadcast_specific_target_update(target_type, target_id)
    case target_type
    when 'callback'
      callback = AgentCallback.find_by(id: target_id)
      broadcast_callback_card_update(callback) if callback
    when 'order'
      order = Order.find_by(id: target_id)
      broadcast_order_card_update(order) if order
    end
  end
  
  private
  
  def broadcast_callback_card_update(callback)
    Rails.logger.info "Broadcasting callback card update for callback #{callback.id}"
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "callback_dashboard",
      target: dom_id(callback, :card),
      partial: "callbacks/dashboard_card",
      locals: { callback: callback }
    )
  end
  
  def broadcast_order_card_update(order)
    Rails.logger.info "Broadcasting order card update for order #{order.id}"
    
    # Note: Orders might be on different pages, so we'll use a more general approach
    Turbo::StreamsChannel.broadcast_replace_to(
      "orders_dashboard", # You can create this channel if needed
      target: dom_id(order),
      partial: "orders/order",
      locals: { order: order }
    )
  end
  
  
  def store_call_analytics(user, call_data)
    # Store rich call data for analytics (implement when needed)
    # Could create CallAnalytic model or add to existing Activity model
    Rails.logger.info "Call Analytics - User: #{user.email}, MOS: #{call_data['mos_score']}, Duration: #{call_data['duration']}, Talk Time: #{call_data['talk_time']}"
    
    # Example: Activity.create!(
    #   user: user,
    #   details: {
    #     call_quality: call_data['mos_score'],
    #     duration: call_data['duration'],
    #     talk_time: call_data['talk_time'],
    #     recording_url: call_data.dig('recording_details', 0, 'url'),
    #     review_link: call_data['company_call_review_share_link']
    #   }
    # )
  end
end