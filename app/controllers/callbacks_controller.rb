class CallbacksController < ApplicationController
  before_action :set_callback, only: [:show, :edit, :update, :destroy]

  def index
    @callbacks = AgentCallback.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @callback = AgentCallback.new
  end

  def create
    @callback = AgentCallback.new(callback_params)
    
    respond_to do |format|
      if @callback.save
        format.html { redirect_to callbacks_path, notice: 'Callback was successfully created.' }
        format.turbo_stream { redirect_to callbacks_path, notice: 'Callback was successfully created.' }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @callback.update(callback_params)
        format.html { redirect_to callbacks_path, notice: 'Callback was successfully updated.' }
        format.turbo_stream { redirect_to callbacks_path, notice: 'Callback was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @callback.destroy
    respond_to do |format|
      format.html { redirect_to callbacks_path, notice: 'Callback was successfully deleted.' }
      format.turbo_stream { head :ok }
    end
  end

  private

  def set_callback
    @callback = AgentCallback.find(params[:id])
  end

  def callback_params
    params.require(:agent_callback).permit(:customer_name, :phone_number, :car_make_model, :year, :product, :zip_code, :status, :follow_up_date, :agent, :notes)
  end
end