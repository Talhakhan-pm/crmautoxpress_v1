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
end
