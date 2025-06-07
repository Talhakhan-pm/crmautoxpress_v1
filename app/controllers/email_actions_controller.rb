class EmailActionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:send_order_email]

  def send_order_email
    email_type = params[:email_type]
    
    unless ['confirmation', 'shipping_notification', 'follow_up'].include?(email_type)
      render json: { success: false, error: 'Invalid email type' }, status: 400
      return
    end

    result = @order.send_email_now(email_type)
    
    respond_to do |format|
      format.json do
        if result[:success]
          render json: { 
            success: true, 
            message: result[:message],
            email_type: email_type,
            order_number: @order.order_number
          }
        else
          render json: { 
            success: false, 
            error: result[:error],
            order_number: @order.order_number
          }, status: 422
        end
      end
      
      format.turbo_stream do
        if result[:success]
          flash.now[:notice] = result[:message]
        else
          flash.now[:alert] = "Failed to send email: #{result[:error]}"
        end
        
        # Update the email status in the timeline/activity feed
        @activities = @order.unified_timeline(10)
        render turbo_stream: [
          turbo_stream.replace("email-status-#{@order.id}", 
            partial: "shared/email_status", 
            locals: { order: @order, last_result: result }
          ),
          turbo_stream.prepend("timeline-#{@order.id}",
            partial: "shared/flash_messages"
          )
        ]
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Order not found' }, status: 404
  end
end