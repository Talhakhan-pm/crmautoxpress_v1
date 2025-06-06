class CommunicationsController < ApplicationController
  before_action :set_callback, only: [:create]
  before_action :set_communication, only: [:destroy]

  def create
    @communication = @callback.communications.build(communication_params)
    @communication.user = current_user

    if @communication.save
      respond_to do |format|
        format.turbo_stream {
          flash.now[:notice] = 'Communication added successfully.'
        }
        format.json { render json: { status: 'success', communication: @communication } }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          flash.now[:alert] = 'Failed to add communication.'
          render turbo_stream: turbo_stream.replace('communication-form', 
                 partial: 'communications/form', 
                 locals: { callback: @callback, communication: @communication })
        }
        format.json { render json: { status: 'error', errors: @communication.errors } }
      end
    end
  end

  def destroy
    @communication.destroy
    
    respond_to do |format|
      format.turbo_stream {
        flash.now[:notice] = 'Communication deleted successfully.'
      }
      format.json { render json: { status: 'success' } }
    end
  end

  private

  def set_callback
    @callback = AgentCallback.find(params[:agent_callback_id])
  end

  def set_communication
    @communication = Communication.find(params[:id])
  end

  def communication_params
    params.require(:communication).permit(:content, :message_type, :is_urgent, :mentions, :parent_communication_id)
  end
end
