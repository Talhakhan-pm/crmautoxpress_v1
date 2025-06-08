class Admin::UsersController < ApplicationController
  before_action :ensure_admin
  before_action :set_user, only: [:show, :update]

  def index
    @users = User.all.order(:email)
  end

  def show
  end

  def update
    if @user.update(user_params)
      respond_to do |format|
        format.html { 
          flash[:notice] = 'User updated successfully.'
          redirect_to admin_users_path 
        }
        format.json { 
          render json: { 
            status: 'success', 
            message: 'User updated successfully',
            user: {
              id: @user.id,
              email: @user.email,
              dialpad_user_id: @user.dialpad_user_id,
              dialpad_configured: @user.dialpad_configured?
            }
          } 
        }
      end
    else
      respond_to do |format|
        format.html { 
          flash[:alert] = 'Failed to update user.'
          redirect_to admin_users_path 
        }
        format.json { 
          render json: { 
            status: 'error', 
            message: 'Failed to update user',
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  private

  def ensure_admin
    unless current_user&.admin?
      respond_to do |format|
        format.html { 
          flash[:alert] = 'Access denied. Admin privileges required.'
          redirect_to root_path 
        }
        format.json { 
          render json: { error: 'Access denied' }, status: :forbidden 
        }
      end
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:dialpad_user_id)
  end
end