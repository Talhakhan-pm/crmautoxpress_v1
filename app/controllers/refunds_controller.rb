class RefundsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_refund, only: [:show, :update]

  def index
    @refunds = Refund.includes(:order, :dispatch, :processing_agent).recent
    @pending_count = @refunds.pending.count
    @total_refund_amount = @refunds.sum(:refund_amount)
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
