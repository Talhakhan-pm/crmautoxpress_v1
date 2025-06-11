class CallbacksController < ApplicationController
  before_action :set_callback, only: [:show, :edit, :update, :destroy, :track_call, :quick_action]

  def index
    # Dashboard view is default, table view available via ?view=table
    if params[:view] == 'table'
      # Table view - show all callbacks with basic ordering
      @callbacks = AgentCallback.all.order(created_at: :desc)
    else
      # Dashboard view (default) - optimized for collaboration features with stable ordering
      @callbacks = AgentCallback.includes(:user, :activities, :source_invoices, communications: :user)
                                .with_communication_stats
                                .order(created_at: :desc)  # Stable order based on callback creation time
                                .limit(20)
      
      # CRITICAL: Preload current callers to eliminate N+1 query (was 20 queries per page load)
      callback_ids = @callbacks.map(&:id)
      @current_callers = User.where(
        current_target_type: 'callback',
        current_target_id: callback_ids,
        call_status: ['calling', 'on_call']
      ).index_by(&:current_target_id)
    end
  end

  def dashboard
    # Redirect to index for backward compatibility
    redirect_to callbacks_path, status: :moved_permanently
  end

  def show
    @callback.track_view
    
    # Preload associations to prevent N+1 queries
    @communications = @callback.communications.includes(:user).recent.limit(20)
    @activities = @callback.activities.includes(:user).recent.limit(10)
    
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
    
    if @callback.save
      # Create communication if message provided
      if params[:communication_message].present?
        @callback.communications.create!(
          user: current_user,
          content: params[:communication_message]
        )
      end
      
      respond_to do |format|
        format.html { 
          flash[:notice] = 'Callback was successfully created.'
          redirect_to callbacks_path 
        }
        format.turbo_stream { 
          flash.now[:notice] = 'Callback was successfully created.'
          @callbacks = AgentCallback.all.order(created_at: :desc)
          redirect_to callbacks_path, status: :see_other
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @callback.update(callback_params)
      # Create communication if message provided
      if params[:communication_message].present?
        @callback.communications.create!(
          user: current_user,
          content: params[:communication_message]
        )
      end
      
      respond_to do |format|
        format.html { 
          flash[:notice] = 'Callback was successfully updated.'
          redirect_to callback_path(@callback) 
        }
        format.turbo_stream { 
          flash.now[:notice] = 'Callback was successfully updated.'
          redirect_to callback_path(@callback), status: :see_other
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @callback.destroy
    respond_to do |format|
      format.html { redirect_to callbacks_path }
      format.turbo_stream { head :ok }
    end
  end

  def track_call
    # Check if user has Dialpad configured
    unless current_user.dialpad_user_id.present?
      respond_to do |format|
        format.json { 
          render json: { 
            status: 'error', 
            message: 'Dialpad not configured for this user' 
          }, status: :unprocessable_entity 
        }
      end
      return
    end
    
    # Initiate call via Dialpad API (user through department)
    result = DialpadService.initiate_call(current_user.dialpad_user_id, @callback.phone_number)
    
    if result[:success]
      # Track which callback this agent is calling
      current_user.update!(
        current_target_type: 'callback',
        current_target_id: @callback.id
      )
      
      # Track successful call initiation
      @callback.create_activity(
        action: 'call_initiated',
        details: "Agent initiated Dialpad call to #{@callback.phone_number}",
        user: current_user
      )
      
      # Update Action-Focused Layout data
      @callback.update_last_contact_date!
      
      respond_to do |format|
        format.json { 
          render json: { 
            status: 'success', 
            message: 'Call initiated successfully via Dialpad',
            dialpad_response: result[:response]
          } 
        }
      end
    else
      # Track failed call attempt
      @callback.create_activity(
        action: 'call_failed',
        details: "Failed to initiate call to #{@callback.phone_number}: #{result[:message]}",
        user: current_user
      )
      
      respond_to do |format|
        format.json { 
          render json: { 
            status: 'error', 
            message: result[:message],
            error: result[:error]
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  def quick_action
    action_type = params[:action_type]
    next_action = params[:next_action]
    
    # Update next action if provided
    @callback.update!(next_action: next_action) if next_action.present?
    
    # Handle disposition actions
    message = case action_type
    when 'called'
      @callback.mark_as_called!(current_user)
      "Marked as called"
    when 'no_answer'
      @callback.mark_as_no_answer!(current_user)
      "Marked as no answer - follow-up scheduled"
    when 'interested'
      @callback.mark_as_interested!
      "Marked as interested - follow-up scheduled"
    when 'later'
      @callback.mark_as_later!
      "Scheduled for later follow-up"
    when 'sale'
      @callback.mark_as_sale!
      "Converted to SALE! 🎉"
    when 'not_interested'
      @callback.mark_as_not_interested!
      "Marked as not interested"
    when nil, ""
      # No disposition selected, just next action update
      if next_action.present?
        "Next action updated"
      else
        "No changes made"
      end
    else
      "Invalid action type"
    end
    
    # Add next action info to message if both disposition and next action were updated
    if action_type.present? && next_action.present?
      message += " and next action updated"
    end
    
    respond_to do |format|
      format.turbo_stream do
        # Set flash message for proper flash system
        flash.now[:notice] = message
        
        # Real-time card update via Turbo Stream
        render turbo_stream: [
          turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@callback, :card),
            partial: "callbacks/dashboard_card",
            locals: { callback: @callback }
          ),
          turbo_stream.replace(
            "flash-messages",
            partial: "shared/flash_messages"
          )
        ]
      end
      format.json { 
        render json: { 
          status: 'success', 
          message: message,
          priority: @callback.priority_level,
          next_action: @callback.next_action
        } 
      }
    end
  end

  def update_next_action
    next_action = params[:next_action]
    
    @callback.update!(next_action: next_action)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@callback, :card),
            partial: "callbacks/dashboard_card",
            locals: { callback: @callback }
          ),
          turbo_stream.append(
            "flash-messages",
            "<div class='alert alert-success alert-dismissible fade show' role='alert'>
              Next action updated successfully!
              <button type='button' class='btn-close' data-bs-dismiss='alert'></button>
            </div>"
          )
        ]
      end
      format.json { 
        render json: { 
          status: 'success', 
          message: 'Next action updated',
          next_action: @callback.next_action
        } 
      }
    end
  end

  private

  def set_callback
    @callback = AgentCallback.includes(:user, :communications, :activities).find(params[:id])
  end

  def callback_params
    params.require(:agent_callback).permit(:customer_name, :phone_number, :car_make_model, :year, :product, :zip_code, :status, :follow_up_date, :agent, :notes)
  end
end