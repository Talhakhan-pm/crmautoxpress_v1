class RefundsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_refund, only: [:show, :update]

  def index
    @refunds = Refund.includes(:order, :dispatch, :processing_agent).recent
    
    # Apply filters
    @refunds = @refunds.where(refund_stage: params[:stage]) if params[:stage].present?
    @refunds = @refunds.by_reason(params[:reason]) if params[:reason].present?
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @refunds = @refunds.joins(:order).where(
        "LOWER(refunds.customer_name) LIKE ? OR LOWER(orders.order_number) LIKE ? OR LOWER(refunds.customer_email) LIKE ?",
        search_term, search_term, search_term
      )
    end
    
    @pending_count = Refund.pending.count
    @total_refund_amount = @refunds.sum(:refund_amount)
    @replacement_eligible_count = @refunds.select(&:replacement_eligible?).count
    
    # For filter dropdowns
    @stages = Refund.refund_stages.keys
    @reasons = Refund.refund_reasons.keys
  end

  def show
  end

  def update
    if @refund.update(refund_params)
      redirect_to @refund, notice: 'Refund updated successfully.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_refund
    @refund = Refund.find(params[:id])
  end

  def refund_params
    params.require(:refund).permit(:refund_stage, :refund_reason, :refund_amount)
  end
end
