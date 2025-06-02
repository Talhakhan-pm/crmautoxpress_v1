class ResolutionController < ApplicationController
  def index
    @stats = calculate_resolution_stats
    @pending_queue = build_resolution_queue
    @resolution_metrics = calculate_resolution_metrics
    @stage_breakdown = stage_performance_breakdown
  end

  def update_stage
    @refund = Refund.find(params[:id])
    
    if @refund.update(refund_params)
      create_stage_activity
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("refund_#{@refund.id}", partial: "simplified_resolution_item", locals: { refund: @refund }),
            turbo_stream.update("resolution-stats-container", partial: "stats", locals: { stats: calculate_resolution_stats })
          ]
        end
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("refund_#{@refund.id}", partial: "resolution_queue_item", locals: { refund: @refund }) }
        format.json { render json: { errors: @refund.errors } }
      end
    end
  end

  def update_notes
    @refund = Refund.find(params[:id])
    
    if @refund.update(notes_params)
      create_notes_activity
      
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("refund_#{@refund.id}", partial: "resolution_queue_item", locals: { refund: @refund }) }
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("refund_#{@refund.id}", partial: "resolution_queue_item", locals: { refund: @refund }) }
        format.json { render json: { errors: @refund.errors } }
      end
    end
  end

  def dispatcher_retry
    @refund = Refund.find(params[:id])
    
    if @refund.update(resolution_stage: 'resolution_completed', dispatcher_notes: params[:retry_notes])
      @refund.create_activity(
        action: 'dispatch_retry_approved',
        details: "Dispatcher approved retry with updated details",
        user: Current.user
      )
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("refund_#{@refund.id}", partial: "simplified_resolution_item", locals: { refund: @refund }),
            turbo_stream.update("resolution-stats-container", partial: "stats", locals: { stats: calculate_resolution_stats })
          ]
        end
        format.json { render json: { status: 'success' } }
      end
    end
  end

  def dispatcher_alternative
    @refund = Refund.find(params[:id])
    
    if @refund.update(
      resolution_stage: 'resolution_completed',
      alternative_part_name: params[:part_name],
      alternative_part_price: params[:part_price],
      price_difference: params[:price_difference],
      part_research_notes: params[:research_notes]
    )
      @refund.create_activity(
        action: 'alternative_part_found',
        details: "Found alternative: #{params[:part_name]} - Price difference: $#{params[:price_difference]}",
        user: Current.user
      )
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("refund_#{@refund.id}", partial: "simplified_resolution_item", locals: { refund: @refund }),
            turbo_stream.update("resolution-stats-container", partial: "stats", locals: { stats: calculate_resolution_stats })
          ]
        end
        format.json { render json: { status: 'success' } }
      end
    end
  end

  def create_replacement_order
    @refund = Refund.find(params[:id])
    replacement = @refund.create_replacement_order
    
    if replacement.present?
      @refund.update!(resolution_stage: 'resolution_completed')
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("refund_#{@refund.id}", partial: "simplified_resolution_item", locals: { refund: @refund }),
            turbo_stream.update("resolution-stats-container", partial: "stats", locals: { stats: calculate_resolution_stats })
          ]
        end
        format.json { render json: { status: 'success', replacement_order: replacement.order_number } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("refund_#{@refund.id}", partial: "resolution_queue_item", locals: { refund: @refund }) }
        format.json { render json: { errors: ['Failed to create replacement order'] } }
      end
    end
  end

  def conversation
    @refund = Refund.find(params[:id])
    @activities = @refund.activities.order(:created_at)
    
    render partial: 'shared/conversation_history', locals: { refund: @refund, activities: @activities }
  end

  def send_message
    @refund = Refund.find(params[:id])
    message = params[:message]
    message_type = params[:message_type] || 'agent'
    
    if message.present?
      # Update appropriate notes field based on message type
      case message_type
      when 'agent'
        current_notes = @refund.agent_notes || ''
        user_name = Current.user&.email&.split('@')&.first&.capitalize || 'Agent'
        new_notes = current_notes.present? ? "#{current_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')} [#{user_name}]: #{message}" : "#{Time.current.strftime('%m/%d %I:%M%p')} [#{user_name}]: #{message}"
        @refund.update!(agent_notes: new_notes)
      when 'dispatcher'
        current_notes = @refund.dispatcher_notes || ''
        user_name = Current.user&.email&.split('@')&.first&.capitalize || 'Dispatcher'
        new_notes = current_notes.present? ? "#{current_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')} [#{user_name}]: #{message}" : "#{Time.current.strftime('%m/%d %I:%M%p')} [#{user_name}]: #{message}"
        @refund.update!(dispatcher_notes: new_notes)
      end
      
      # Create activity
      @refund.create_activity(
        action: 'message_sent',
        details: "#{message_type.capitalize} sent message: #{message.truncate(100)}",
        user: Current.user
      )
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("refund_#{@refund.id}", partial: "simplified_resolution_item", locals: { refund: @refund }),
            turbo_stream.update("conversation_#{@refund.id}", partial: "shared/conversation_history", locals: { refund: @refund, activities: @refund.activities.order(:created_at) })
          ]
        end
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.json { render json: { errors: ['Message cannot be blank'] } }
      end
    end
  end

  def mark_viewed
    @refund = Refund.find(params[:id])
    # Could track viewed status in database if needed
    render json: { status: 'success' }
  end

  # Quick action methods
  def mark_clarified
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'pending_dispatch_decision')
    render_quick_action_response
  end

  def move_to_agent_review
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'pending_customer_clarification')
    
    @refund.create_activity(
      action: 'moved_to_agent_review',
      details: 'Case moved to Agent Review for customer communication',
      user: Current.user
    )
    
    render_quick_action_response
  end

  def move_to_dispatcher_review
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'pending_dispatch_decision')
    
    @refund.create_activity(
      action: 'moved_to_dispatcher_review', 
      details: 'Case moved to Dispatcher Review for business decision',
      user: Current.user
    )
    
    render_quick_action_response
  end

  def request_info
    @refund = Refund.find(params[:id])
    # Add system note about requesting more info
    @refund.create_activity(
      action: 'info_requested',
      details: 'Additional information requested from customer',
      user: Current.user
    )
    render_quick_action_response
  end

  def escalate
    @refund = Refund.find(params[:id])
    @refund.create_activity(
      action: 'escalated',
      details: 'Case escalated to manager',
      user: Current.user
    )
    render_quick_action_response
  end

  def approve_retry
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'resolution_completed')
    render_quick_action_response
  end

  def suggest_alternative
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'resolution_completed')
    render_quick_action_response
  end

  def approve_refund
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'resolution_completed')
    render_quick_action_response
  end

  def customer_approved
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'resolution_completed')
    render_quick_action_response
  end

  def customer_declined
    @refund = Refund.find(params[:id])
    @refund.update!(resolution_stage: 'resolution_completed')
    render_quick_action_response
  end

  def follow_up
    @refund = Refund.find(params[:id])
    @refund.create_activity(
      action: 'follow_up',
      details: 'Follow-up scheduled with customer',
      user: Current.user
    )
    render_quick_action_response
  end

  # Return Resolution Actions
  def authorize_return_and_refund
    @refund = Refund.find(params[:id])
    
    if @refund.authorize_return_and_refund!
      render_quick_action_response
    else
      render json: { errors: ['Cannot authorize return from current state'] }, status: :unprocessable_entity
    end
  end

  def authorize_return_and_replacement
    @refund = Refund.find(params[:id])
    
    if @refund.authorize_return_and_replacement!
      render_quick_action_response
    else
      render json: { errors: ['Cannot authorize return and replacement from current state'] }, status: :unprocessable_entity
    end
  end

  def generate_return_label
    @refund = Refund.find(params[:id])
    carrier = params[:carrier] || 'FedEx'
    label_url = params[:label_url]
    
    if @refund.generate_return_label!(carrier: carrier, label_url: label_url)
      render_quick_action_response
    else
      render json: { errors: ['Cannot generate return label from current state'] }, status: :unprocessable_entity
    end
  end

  def mark_return_shipped
    @refund = Refund.find(params[:id])
    tracking_number = params[:tracking_number]
    
    if @refund.mark_return_shipped!(tracking_number: tracking_number)
      render_quick_action_response
    else
      render json: { errors: ['Cannot mark return as shipped from current state'] }, status: :unprocessable_entity
    end
  end

  def mark_return_received
    @refund = Refund.find(params[:id])
    condition_notes = params[:condition_notes]
    
    if @refund.mark_return_received!(condition_notes: condition_notes)
      render_quick_action_response
    else
      render json: { errors: ['Cannot mark return as received from current state'] }, status: :unprocessable_entity
    end
  end

  # New Dispatcher Sourcing Actions
  def accept_delay
    @refund = Refund.find(params[:id])
    delay_days = params[:delay_days] || 3
    
    @refund.update!(
      resolution_stage: 'resolution_completed',
      dispatcher_notes: "#{@refund.dispatcher_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')}: Sourcing complete - Approved #{delay_days} day delivery delay",
      dispatcher_decision: 'delay_approved',
      delay_duration: delay_days,
      refund_stage: 'cancelled_refund'
    )
    
    @refund.create_activity(
      action: 'dispatcher_decision',
      details: "Dispatcher confirmed sourcing option: #{delay_days}-day delay required",
      user: Current.user
    )
    
    render_quick_action_response
  end

  def request_price_increase
    @refund = Refund.find(params[:id])
    additional_amount = params[:additional_amount]
    
    @refund.update!(
      resolution_stage: 'resolution_completed',
      dispatcher_notes: "#{@refund.dispatcher_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')}: Sourcing complete - Approved $#{additional_amount} price increase",
      dispatcher_decision: 'price_increase_approved',
      additional_cost: additional_amount
    )
    
    @refund.create_activity(
      action: 'dispatcher_decision',
      details: "Dispatcher confirmed sourcing option: $#{additional_amount} price increase required",
      user: Current.user
    )
    
    render_quick_action_response
  end

  def send_compatible_alternative
    @refund = Refund.find(params[:id])
    alternative_part = params[:alternative_part_name]
    
    @refund.update!(
      resolution_stage: 'resolution_completed',
      dispatcher_notes: "#{@refund.dispatcher_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')}: Compatible alternative approved: #{alternative_part}",
      dispatcher_decision: 'compatible_alternative_approved',
      alternative_part_name: alternative_part
    )
    
    @refund.create_activity(
      action: 'dispatcher_decision',
      details: "Dispatcher confirmed sourcing option: Compatible alternative #{alternative_part}",
      user: Current.user
    )
    
    render_quick_action_response
  end

  def dispatcher_refund
    @refund = Refund.find(params[:id])
    refund_reason = params[:refund_reason] || 'Part not economical to source'
    
    @refund.update!(
      resolution_stage: 'resolution_completed',
      dispatcher_notes: "#{@refund.dispatcher_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')}: Decision: Process refund - #{refund_reason}",
      dispatcher_decision: 'issue_refund',
      refund_stage: 'processing_refund'
    )
    
    @refund.create_activity(
      action: 'dispatcher_refund',
      details: "Dispatcher determined sourcing not viable: #{refund_reason}",
      user: Current.user
    )
    
    render_quick_action_response
  end

  # Complete refund processing - moves from processing_refund to refunded
  def complete_refund
    @refund = Refund.find(params[:id])
    
    if @refund.refund_stage == 'processing_refund'
      @refund.update!(
        refund_stage: 'refunded', 
        completed_at: Time.current,
        dispatcher_notes: "#{@refund.dispatcher_notes}\n\n#{Time.current.strftime('%m/%d %I:%M%p')}: Refund completed by dispatcher"
      )
      
      @refund.create_activity(
        action: 'refund_completed',
        details: "Refund completed by dispatcher - $#{@refund.refund_amount}",
        user: Current.user
      )
      
      render_quick_action_response
    else
      render json: { errors: ['Cannot complete refund from current stage'] }, status: :unprocessable_entity
    end
  end

  private

  def calculate_resolution_stats
    total_pending = Refund.needs_resolution.count
    
    {
      total_pending_resolution: total_pending,
      agent_clarification: Refund.awaiting_agent_action.count,
      dispatcher_decision: Refund.awaiting_dispatcher_action.count,
      overdue_resolutions: Refund.needs_resolution.where('created_at < ?', 2.days.ago).count,
      avg_resolution_time: calculate_avg_resolution_time,
      resolution_completion_rate: calculate_completion_rate,
      urgent_priority: Refund.needs_resolution.where(priority: 'urgent').count
    }
  end

  def build_resolution_queue
    base_query = Refund.needs_resolution
                      .includes(:order, :processing_agent)
                      .order(:priority, :created_at)

    # Apply filters if present
    query = base_query
    query = query.where(id: params[:refund_id]) if params[:refund_id].present?
    query = query.by_resolution_stage(params[:stage]) if params[:stage].present?
    query = query.by_priority(params[:priority]) if params[:priority].present?
    query = query.by_agent(params[:agent_id]) if params[:agent_id].present?
    
    if params[:overdue] == 'true'
      query = query.where('created_at < ?', 2.days.ago)
    end

    query.limit(50) # Limit for performance
  end

  def calculate_resolution_metrics
    refunds = Refund.needs_resolution
    
    {
      by_stage: {
        pending_customer_clarification: refunds.by_resolution_stage('pending_customer_clarification').count,
        pending_dispatch_decision: refunds.by_resolution_stage('pending_dispatch_decision').count
      },
      by_priority: {
        urgent: refunds.where(priority: 'urgent').count,
        high: refunds.where(priority: 'high').count,
        standard: refunds.where(priority: 'standard').count,
        low: refunds.where(priority: 'low').count
      },
      by_age: {
        new: refunds.where('created_at > ?', 1.day.ago).count,
        aging: refunds.where('created_at BETWEEN ? AND ?', 2.days.ago, 1.day.ago).count,
        overdue: refunds.where('created_at < ?', 2.days.ago).count
      }
    }
  end

  def stage_performance_breakdown
    Refund.needs_resolution.group(:resolution_stage).group(:priority).count
  end

  def calculate_avg_resolution_time
    completed_resolutions = Refund.where(resolution_stage: 'resolution_completed')
                                 .where('updated_at > ?', 30.days.ago)
    
    return 0 if completed_resolutions.empty?
    
    total_hours = completed_resolutions.sum do |refund|
      ((refund.updated_at - refund.created_at) / 1.hour).round(1)
    end
    
    (total_hours / completed_resolutions.count / 24).round(1) # Convert to days
  end

  def calculate_completion_rate
    total_resolutions = Refund.where('created_at > ?', 30.days.ago).count
    completed_resolutions = Refund.where(resolution_stage: 'resolution_completed')
                                 .where('created_at > ?', 30.days.ago).count
    
    return 0 if total_resolutions.zero?
    
    ((completed_resolutions.to_f / total_resolutions) * 100).round(1)
  end

  def create_stage_activity
    return unless @refund.resolution_stage_changed?
    
    @refund.create_activity(
      action: 'resolution_stage_updated',
      details: "Resolution stage changed from #{@refund.resolution_stage_was} to #{@refund.resolution_stage}",
      user: Current.user
    )
  end

  def create_notes_activity
    changed_fields = []
    changed_fields << 'agent notes' if @refund.agent_notes_changed?
    changed_fields << 'dispatcher notes' if @refund.dispatcher_notes_changed?
    
    return if changed_fields.empty?
    
    @refund.create_activity(
      action: 'resolution_notes_updated',
      details: "Updated #{changed_fields.join(', ')}",
      user: Current.user
    )
  end

  def refund_params
    params.require(:refund).permit(:resolution_stage, :agent_notes, :dispatcher_notes, 
                                   :corrected_customer_details, :part_research_notes, :price_difference, 
                                   :alternative_part_name, :alternative_part_price, :dispatcher_decision,
                                   :delay_duration, :additional_cost, :agent_instructions)
  end

  def notes_params
    params.require(:refund).permit(:agent_notes, :dispatcher_notes, 
                                   :corrected_customer_details, :part_research_notes, :price_difference, 
                                   :alternative_part_name, :alternative_part_price, :dispatcher_decision,
                                   :delay_duration, :additional_cost, :agent_instructions)
  end

  def render_quick_action_response
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("refund_#{@refund.id}", partial: "simplified_resolution_item", locals: { refund: @refund }),
          turbo_stream.update("resolution-stats-container", partial: "stats", locals: { stats: calculate_resolution_stats })
        ]
      end
      format.json { render json: { success: true } }
    end
  end
end