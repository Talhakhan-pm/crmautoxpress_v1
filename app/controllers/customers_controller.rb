class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update]

  def index
    @customers = Customer.includes(:agent_callbacks)
                        .order(created_at: :desc)
    
    # Filter by search
    if params[:search].present?
      @customers = @customers.where(
        "name LIKE ? OR phone_number LIKE ? OR email LIKE ?", 
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    
    # Filter by status
    if params[:status].present?
      @customers = @customers.where(status: params[:status])
    end
    
    # Filter by source
    if params[:source].present?
      case params[:source]
      when 'google_ads'
        @customers = @customers.google_ads
      when 'with_callbacks'
        @customers = @customers.with_callbacks
      end
    end
    
    # Track views for loaded customers
    @customers.limit(50).each(&:track_view)
  end

  def show
    @customer.track_view
    @callbacks = @customer.agent_callbacks.includes(:user, :activities).order(created_at: :desc)
    @recent_activities = @customer.activities.includes(:user).recent.limit(10)
  end

  def edit
    @customer.track_view
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.turbo_stream { render :update }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :phone_number, :email, :full_address, 
                                   :source_campaign, :gclid, :utm_source, :utm_campaign, 
                                   :status)
  end
end