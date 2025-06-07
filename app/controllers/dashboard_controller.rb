class DashboardController < ApplicationController
  def index
    @period = params[:period] || 'today'
    @stats = calculate_dashboard_stats(@period)
    @recent_activities = recent_activities(@period)
    @chart_data = prepare_chart_data(@period)
    @top_performers = top_performing_agents(@period)
    @upcoming_followups = upcoming_followups

    respond_to do |format|
      format.html
      format.json do
        render json: {
          stats: @stats,
          chart_data: @chart_data,
          top_performers: @top_performers,
          recent_activities: @recent_activities.map { |activity| 
            render_to_string(partial: 'activities/activity', locals: { activity: activity })
          }
        }
      end
    end
  end

  private

  def calculate_dashboard_stats(period = 'today')
    date_range = get_date_range(period)
    
    total_leads = AgentCallback.where(created_at: date_range).count
    sales_count = AgentCallback.where(created_at: date_range, status: ['sale', 'payment_link']).count
    
    {
      total_leads: total_leads,
      pending_leads: AgentCallback.where(created_at: date_range).pending.count,
      sales_closed: sales_count,
      conversion_rate: total_leads > 0 ? ((sales_count.to_f / total_leads) * 100).round(1) : 0,
      follow_ups_due: AgentCallback.follow_up.where(follow_up_date: Date.current..3.days.from_now).count,
      total_agents: User.count,
      active_agents_today: User.joins(:agent_callbacks)
                              .where(agent_callbacks: { created_at: date_range })
                              .distinct.count,
      avg_lead_value: calculate_avg_lead_value(period),
      hot_leads: AgentCallback.where(created_at: date_range, status: 'follow_up').count
    }
  end

  def recent_activities(period = 'today')
    date_range = get_date_range(period)
    Activity.includes(:user, :trackable)
            .where(trackable_type: 'AgentCallback', created_at: date_range)
            .order(created_at: :desc)
            .limit(8)
  end

  def prepare_chart_data(period = 'today')
    {
      lead_status_distribution: lead_status_data(period),
      daily_leads_trend: daily_leads_trend(period),
      conversion_funnel: conversion_funnel_data(period),
      agent_performance: agent_performance_data(period),
      popular_car_brands: popular_car_brands_data(period)
    }
  end

  def top_performing_agents(period = 'today')
    date_range = get_date_range(period)
    User.joins(:agent_callbacks)
        .where(agent_callbacks: { created_at: date_range })
        .group('users.id', 'users.email')
        .select('users.*, COUNT(agent_callbacks.id) as total_leads, 
                 COUNT(CASE WHEN agent_callbacks.status IN (3, 4) THEN 1 END) as sales_count')
        .order('sales_count DESC, total_leads DESC')
        .limit(5)
        .map do |user|
          {
            name: user.email.split('@').first.humanize,
            email: user.email,
            total_leads: user.total_leads,
            sales: user.sales_count,
            conversion_rate: user.total_leads > 0 ? ((user.sales_count.to_f / user.total_leads) * 100).round(1) : 0
          }
        end
  end

  def upcoming_followups
    AgentCallback.follow_up
                 .where(follow_up_date: Date.current..7.days.from_now)
                 .includes(:user)
                 .order(:follow_up_date)
                 .limit(10)
  end

  def lead_status_data(period = 'today')
    date_range = get_date_range(period)
    AgentCallback.where(created_at: date_range).group(:status).count.transform_keys do |status|
      status.humanize.titleize
    end
  end

  def daily_leads_trend(period = 'today')
    days = period == 'today' ? 1 : (period == 'week' ? 7 : 30)
    start_date = days.days.ago.to_date
    
    start_date.upto(Date.current).map do |date|
      {
        date: date.strftime(period == 'month' ? '%m/%d' : '%a'),
        leads: AgentCallback.where(created_at: date.beginning_of_day..date.end_of_day).count,
        sales: AgentCallback.where(
          created_at: date.beginning_of_day..date.end_of_day,
          status: ['sale', 'payment_link']
        ).count
      }
    end
  end

  def conversion_funnel_data(period = 'today')
    date_range = get_date_range(period)
    total = AgentCallback.where(created_at: date_range).count
    return [] if total.zero?

    [
      { stage: 'Total Leads', count: total, percentage: 100 },
      { stage: 'Qualified', count: AgentCallback.where(created_at: date_range).where.not(status: 'not_interested').count, 
        percentage: ((AgentCallback.where(created_at: date_range).where.not(status: 'not_interested').count.to_f / total) * 100).round(1) },
      { stage: 'Follow-up', count: AgentCallback.where(created_at: date_range).follow_up.count,
        percentage: ((AgentCallback.where(created_at: date_range).follow_up.count.to_f / total) * 100).round(1) },
      { stage: 'Sales Closed', count: AgentCallback.where(created_at: date_range, status: ['sale', 'payment_link']).count,
        percentage: ((AgentCallback.where(created_at: date_range, status: ['sale', 'payment_link']).count.to_f / total) * 100).round(1) }
    ]
  end

  def agent_performance_data(period = 'today')
    date_range = get_date_range(period)
    User.joins(:agent_callbacks)
        .where(agent_callbacks: { created_at: date_range })
        .group('users.email')
        .select('users.email, COUNT(agent_callbacks.id) as total_leads,
                 COUNT(CASE WHEN agent_callbacks.status IN (3, 4) THEN 1 END) as sales')
        .map do |user|
          {
            agent: user.email.split('@').first.humanize,
            leads: user.total_leads,
            sales: user.sales,
            rate: user.total_leads > 0 ? ((user.sales.to_f / user.total_leads) * 100).round(1) : 0
          }
        end
  end

  def popular_car_brands_data(period = 'today')
    date_range = get_date_range(period)
    AgentCallback.where(created_at: date_range).where.not(car_make_model: [nil, ''])
                 .group(:car_make_model)
                 .count
                 .sort_by { |_, count| -count }
                 .first(6)
                 .to_h
  end

  def calculate_avg_lead_value(period = 'today')
    date_range = get_date_range(period)
    sales_count = AgentCallback.where(created_at: date_range, status: ['sale', 'payment_link']).count
    sales_count * 1500 # Assuming average automotive sale commission
  end

  def get_date_range(period)
    case period
    when 'today'
      Date.current.beginning_of_day..Date.current.end_of_day
    when 'week'
      7.days.ago.beginning_of_day..Date.current.end_of_day
    when 'month'
      30.days.ago.beginning_of_day..Date.current.end_of_day
    else
      Date.current.beginning_of_day..Date.current.end_of_day
    end
  end
end