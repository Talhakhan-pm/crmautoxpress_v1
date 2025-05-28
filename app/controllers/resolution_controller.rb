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
      resolution_stage: 'pending_customer_approval',
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

  private

  def calculate_resolution_stats
    total_pending = Refund.needs_resolution.count
    
    {
      total_pending_resolution: total_pending,
      agent_clarification: Refund.awaiting_agent_action.count,
      dispatcher_decision: Refund.awaiting_dispatcher_action.count,
      customer_approval: Refund.awaiting_customer_action.count,
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
        pending_dispatch_decision: refunds.by_resolution_stage('pending_dispatch_decision').count,
        pending_customer_approval: refunds.by_resolution_stage('pending_customer_approval').count
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
                                   :alternative_part_name, :alternative_part_price)
  end

  def notes_params
    params.require(:refund).permit(:agent_notes, :dispatcher_notes, 
                                   :corrected_customer_details, :part_research_notes, :price_difference, 
                                   :alternative_part_name, :alternative_part_price)
  end
end