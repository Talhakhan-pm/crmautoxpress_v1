class CallbacksController < ApplicationController
  before_action :set_callback, only: [:show, :edit, :update, :destroy]

  def index
    @callbacks = AgentCallback.all.order(created_at: :desc)
  end

  def show
    @callback.track_view
    
    respond_to do |format|
      format.html
      format.json { 
        render json: {
          id: @callback.id,
          customer_name: @callback.customer_name,
          phone_number: @callback.phone_number,
          product: @callback.product,
          year: @callback.year,
          car_make_model: @callback.car_make_model,
          status: @callback.status
        }
      }
    end
  end

  def new
    @callback = AgentCallback.new
  end

  def create
    @callback = current_user.agent_callbacks.build(callback_params)
    
    # Store Google Ads data if provided
    if params[:google_ads_gclid].present?
      session[:google_ads_data] = {
        gclid: params[:google_ads_gclid],
        utm_source: params[:google_ads_utm_source],
        utm_campaign: params[:google_ads_utm_campaign]
      }
    end
    
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