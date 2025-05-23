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
    
    if @callback.save
      redirect_to callbacks_path, notice: 'Callback was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @callback.update(callback_params)
      redirect_to callbacks_path, notice: 'Callback was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @callback.destroy
    redirect_to callbacks_path, notice: 'Callback was successfully deleted.'
  end

  private

  def set_callback
    @callback = AgentCallback.find(params[:id])
  end

  def callback_params
    params.require(:agent_callback).permit(:customer_name, :phone_number, :car_make_model, :year, :product, :zip_code, :status, :follow_up_date, :agent, :notes)
  end
end