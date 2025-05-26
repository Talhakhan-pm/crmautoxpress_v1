module DispatchesHelper
  def timeline_status_class(dispatch, status)
    case dispatch.dispatch_status
    when 'pending'
      status == 'pending' ? 'active' : 'pending'
    when 'processing'
      case status
      when 'pending' then 'completed'
      when 'processing' then 'active'
      else 'pending'
      end
    when 'shipped'
      case status
      when 'pending', 'processing' then 'completed'
      when 'shipped' then 'active'
      else 'pending'
      end
    when 'completed'
      status == 'completed' ? 'active' : 'completed'
    else
      'pending'
    end
  end

  def calculate_progress_percentage(dispatch)
    case dispatch.dispatch_status
    when 'pending' then 0
    when 'processing' then 33
    when 'shipped' then 66
    when 'completed' then 100
    else 0
    end
  end

  def processing_date(dispatch)
    case dispatch.dispatch_status
    when 'pending' then 'Pending'
    when 'processing' then Date.current.strftime('%b %d')
    when 'shipped', 'completed' then dispatch.updated_at.strftime('%b %d')
    else 'Pending'
    end
  end

  def shipped_date(dispatch)
    case dispatch.dispatch_status
    when 'pending', 'processing' then 'Pending'
    when 'shipped' then Date.current.strftime('%b %d')
    when 'completed' then dispatch.updated_at.strftime('%b %d')
    else 'Pending'
    end
  end

  def completed_date(dispatch)
    case dispatch.dispatch_status
    when 'pending', 'processing', 'shipped' then 'Pending'
    when 'completed' then dispatch.updated_at.strftime('%b %d')
    else 'Pending'
    end
  end

  # Status badge styling helpers
  def status_badge_class(status, type = 'dispatch')
    base_class = "status-badge"
    case type
    when 'dispatch'
      "#{base_class} dispatch-#{status}"
    when 'payment'
      "#{base_class} payment-#{status}"
    when 'shipment'
      "#{base_class} shipment-#{status}"
    else
      "#{base_class} #{status}"
    end
  end

  # Status transition validation
  def can_transition_to?(current_status, new_status)
    valid_transitions = {
      'pending' => ['assigned', 'processing', 'cancelled'],
      'assigned' => ['processing', 'cancelled'],
      'processing' => ['shipped', 'cancelled'],
      'shipped' => ['completed', 'cancelled'],
      'completed' => [], # No transitions from completed
      'cancelled' => [] # No transitions from cancelled
    }
    
    valid_transitions[current_status]&.include?(new_status) || false
  end

  # Smart status suggestions
  def next_suggested_status(dispatch)
    case dispatch.dispatch_status
    when 'pending'
      dispatch.supplier_name.present? ? 'processing' : 'assigned'
    when 'assigned'
      'processing'
    when 'processing'
      dispatch.paid? ? 'shipped' : nil
    when 'shipped'
      'completed'
    else
      nil
    end
  end

  # Status emoji mapping
  def status_emoji(status, type = 'dispatch')
    emoji_mapping = {
      'dispatch' => {
        'pending' => '⏳',
        'assigned' => '📋',
        'processing' => '⚙️',
        'shipped' => '🚚',
        'completed' => '✅',
        'cancelled' => '❌'
      },
      'payment' => {
        'payment_pending' => '💳',
        'paid' => '✅',
        'failed' => '❌',
        'refunded' => '🔄',
        'partially_paid' => '⚡'
      },
      'shipment' => {
        'shipment_pending' => '📦',
        'picked_up' => '🚛',
        'in_transit' => '🚚',
        'delivered' => '🏠',
        'exception' => '⚠️',
        'returned_to_sender' => '↩️'
      }
    }
    
    emoji_mapping.dig(type, status) || '●'
  end

  # Calculate days in current status
  def days_in_status(dispatch)
    return 0 unless dispatch.updated_at
    
    (Date.current - dispatch.updated_at.to_date).to_i
  end

  # Status urgency indicator
  def status_urgency(dispatch)
    days = days_in_status(dispatch)
    
    case dispatch.dispatch_status
    when 'pending'
      days > 1 ? 'urgent' : 'normal'
    when 'processing'
      days > 3 ? 'urgent' : days > 1 ? 'warning' : 'normal'
    when 'shipped'
      days > 7 ? 'urgent' : 'normal'
    else
      'normal'
    end
  end

  # Financial status indicators
  def profit_status_class(profit)
    return 'profit-zero' if profit.zero?
    profit > 0 ? 'profit-positive' : 'profit-negative'
  end

  def profit_margin_class(margin)
    return 'margin-zero' if margin.zero?
    
    case margin
    when 0..10
      'margin-low'
    when 10..25
      'margin-good'
    when 25..Float::INFINITY
      'margin-excellent'
    else
      'margin-negative'
    end
  end

  # Tracking information helpers
  def tracking_status_icon(dispatch)
    return '📍' if dispatch.tracking_number.present?
    return '🚚' if dispatch.shipped?
    '📦'
  end

  def estimate_delivery_date(dispatch)
    return nil unless dispatch.shipped?
    return dispatch.order&.estimated_delivery if dispatch.order&.estimated_delivery
    
    # Default estimate: 3-5 business days from ship date
    ship_date = dispatch.updated_at.to_date
    (ship_date + 3.days).strftime('%b %d')
  end

  # Status workflow helpers
  def workflow_completion_percentage(dispatch)
    statuses = ['pending', 'processing', 'shipped', 'completed']
    current_index = statuses.index(dispatch.dispatch_status) || 0
    
    return 100 if dispatch.completed?
    return 0 if dispatch.cancelled?
    
    ((current_index + 1).to_f / statuses.length * 100).round
  end

  def required_fields_for_status(status)
    case status
    when 'processing'
      ['supplier_name', 'supplier_cost']
    when 'shipped'
      ['tracking_number']
    when 'completed'
      ['tracking_number', 'shipment_status']
    else
      []
    end
  end

  def missing_required_fields(dispatch, target_status)
    required = required_fields_for_status(target_status)
    required.select { |field| dispatch.send(field).blank? }
  end
end
