Current State Analysis
Your app has:

✅ User model (with Devise)
✅ AgentCallback model
❌ No relationship between them
❌ No activity tracking yet

Recommended Approach: Create Relationships First
1. Generate the Activity Migration
bashrails generate migration CreateActivities trackable:references{polymorphic} user:references action:string field_changed:string old_value:text new_value:text ip_address:string user_agent:text
2. Add User-Callback Relationship
bashrails generate migration AddUserToAgentCallbacks user:references
3. Update Your Models
ruby# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  has_many :agent_callbacks, dependent: :destroy
  has_many :activities, dependent: :destroy
end

# app/models/agent_callback.rb
class AgentCallback < ApplicationRecord
  belongs_to :user
  has_many :activities, as: :trackable, dependent: :destroy
  
  # Keep your existing code
  enum status: {
    pending: 0,
    later: 1,
    interested: 2,
    purchased: 3,
    answered: 4,
    sold: 5
  }

  validates :customer_name, presence: true
  validates :phone_number, presence: true
  validates :product, presence: true
  validates :status, presence: true

  # Add activity tracking
  include Trackable
  
  after_create_commit { broadcast_prepend_to "callbacks", target: "callbacks" }
  after_update_commit { broadcast_replace_to "callbacks" }
  after_destroy_commit { broadcast_remove_to "callbacks" }
end

# app/models/activity.rb
class Activity < ApplicationRecord
  belongs_to :trackable, polymorphic: true
  belongs_to :user
  
  validates :action, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }
end
4. Create the Trackable Concern
ruby# app/models/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :activities, as: :trackable, dependent: :destroy
    after_update :track_changes, if: :saved_changes?
    after_create :track_creation
  end

  private

  def track_changes
    return unless Current.user # Only track if we have a current user
    
    saved_changes.each do |field, changes|
      next if field == 'updated_at' # Skip timestamp changes
      
      old_value, new_value = changes
      Activity.create!(
        trackable: self,
        user: Current.user,
        action: 'updated',
        field_changed: field,
        old_value: old_value&.to_s,
        new_value: new_value&.to_s,
        ip_address: Current.ip_address,
        user_agent: Current.user_agent
      )
    end
  end

  def track_creation
    return unless Current.user
    
    Activity.create!(
      trackable: self,
      user: Current.user,
      action: 'created',
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  end
  
  def track_view
    return unless Current.user
    
    Activity.create!(
      trackable: self,
      user: Current.user,
      action: 'viewed',
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  end
end
5. Set Up Current Context
ruby# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :ip_address, :user_agent
end
6. Update Application Controller
ruby# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_attributes
  
  private
  
  def set_current_attributes
    Current.user = current_user if user_signed_in?
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end
end
7. Update Callbacks Controller
ruby# app/controllers/callbacks_controller.rb
class CallbacksController < ApplicationController
  before_action :set_callback, only: [:show, :edit, :update, :destroy]

  def index
    @callbacks = current_user.agent_callbacks.order(created_at: :desc)
  end

  def show
    @callback.track_view # Track when someone views the callback
  end

  def create
    @callback = current_user.agent_callbacks.build(callback_params)
    
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

  # ... rest of your controller

  private

  def set_callback
    @callback = current_user.agent_callbacks.find(params[:id])
  end

  def callback_params
    params.require(:agent_callback).permit(:customer_name, :phone_number, :car_make_model, :year, :product, :zip_code, :status, :follow_up_date, :agent, :notes)
  end
end


The callback should look like something like this:

<main class="main-content">
        <!-- Header -->
        <header class="main-header">
            <div class="header-left">
                <h1>Callback #CB-2025-1234</h1>
                <div class="breadcrumb">CRM › Callbacks › Callback Details</div>
            </div>
            <div class="header-actions">
                <button class="btn btn-secondary">
                    <i class="fas fa-phone"></i>
                    Call Customer
                </button>
                <button class="btn btn-primary">
                    <i class="fas fa-edit"></i>
                    Edit Callback
                </button>
            </div>
        </header>

        <!-- Content -->
        <div class="content-container">
            <!-- Main Callback Detail -->
            <div class="callback-detail">
                <div class="callback-header">
                    <h2 class="callback-title">Callback Details</h2>
                </div>
                
                <div class="callback-content">
                    <div class="tab-container">
                        <div class="tab-list">
                            <div class="tab-item active">Details</div>
                            <div class="tab-item">Performance</div>
                            <div class="tab-item">Analytics</div>
                        </div>
                    </div>

                    <!-- Tab Content: Details -->
                    <div class="tab-content active">
                        <div class="field-group">
                            <div class="field">
                                <div class="field-label">Customer</div>
                                <div class="field-value">Joe Martinez</div>
                            </div>
                            <div class="field">
                                <div class="field-label">Phone</div>
                                <div class="field-value">(817) 489-4064</div>
                            </div>
                        </div>

                        <div class="field-group">
                            <div class="field">
                                <div class="field-label">Product</div>
                                <div class="field-value">Motor Mounts</div>
                            </div>
                            <div class="field">
                                <div class="field-label">Status</div>
                                <div class="field-value">
                                    <span class="status-badge status-pending">Pending</span>
                                </div>
                            </div>
                        </div>

                        <div class="field-group">
                            <div class="field">
                                <div class="field-label">Vehicle</div>
                                <div class="field-value">2007 Ford Fusion</div>
                            </div>
                            <div class="field">
                                <div class="field-label">Assigned Agent</div>
                                <div class="field-value">Ayesha Rahman</div>
                            </div>
                        </div>

                        <div class="field">
                            <div class="field-label">Notes</div>
                            <div class="field-value">Customer interested in OEM parts. Follow up next week for pricing.</div>
                        </div>
                    </div>

                    <!-- Tab Content: Performance (hidden by default) -->
                    <div class="tab-content" style="display: none;">
                        <div class="metrics-grid">
                            <div class="metric-card">
                                <div class="metric-value">7</div>
                                <div class="metric-label">Total Views</div>
                            </div>
                            <div class="metric-card">
                                <div class="metric-value">3</div>
                                <div class="metric-label">Edits Made</div>
                            </div>
                            <div class="metric-card">
                                <div class="metric-value">2</div>
                                <div class="metric-label">Agents Involved</div>
                            </div>
                        </div>

                        <div class="performance-section">
                            <h3 class="section-title">
                                <i class="fas fa-users"></i>
                                Agent Performance
                            </h3>
                            <div class="agent-list">
                                <div class="agent-row">
                                    <div class="agent-info">
                                        <div class="agent-avatar">AR</div>
                                        <div class="agent-name">Ayesha Rahman</div>
                                    </div>
                                    <div class="agent-stats">
                                        <div class="stat-item">
                                            <div class="stat-value">5</div>
                                            <div class="stat-label">Views</div>
                                        </div>
                                        <div class="stat-item">
                                            <div class="stat-value">2</div>
                                            <div class="stat-label">Edits</div>
                                        </div>
                                        <div class="stat-item">
                                            <div class="stat-value">45m</div>
                                            <div class="stat-label">Time Spent</div>
                                        </div>
                                    </div>
                                    <a href="#" class="view-details">View Details</a>
                                </div>
                                <div class="agent-row">
                                    <div class="agent-info">
                                        <div class="agent-avatar">MK</div>
                                        <div class="agent-name">Murtaza Khan</div>
                                    </div>
                                    <div class="agent-stats">
                                        <div class="stat-item">
                                            <div class="stat-value">2</div>
                                            <div class="stat-label">Views</div>
                                        </div>
                                        <div class="stat-item">
                                            <div class="stat-value">1</div>
                                            <div class="stat-label">Edits</div>
                                        </div>
                                        <div class="stat-item">
                                            <div class="stat-value">12m</div>
                                            <div class="stat-label">Time Spent</div>
                                        </div>
                                    </div>
                                    <a href="#" class="view-details">View Details</a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Activity Panel -->
            <div class="activity-panel">
                <div class="activity-header">
                    <div class="activity-title">
                        <i class="fas fa-history"></i>
                        Activity Log
                        <span class="activity-count">12</span>
                    </div>
                </div>

                <div class="activity-filters">
                    <div class="filter-chip active">All</div>
                    <div class="filter-chip">Views</div>
                    <div class="filter-chip">Edits</div>
                    <div class="filter-chip">Calls</div>
                </div>

                <div class="activity-list">
                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Status changed</strong> from Pending to Follow-up Later
                                </div>
                                <div class="activity-time">2 min ago</div>
                            </div>
                            <div class="activity-change">
                                <span class="change-from">Pending</span>
                                <i class="fas fa-arrow-right" style="color: #6b7280; font-size: 10px;"></i>
                                <span class="change-to">Follow-up Later</span>
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">AR</div>
                                <span class="user-name">Ayesha Rahman</span>
                            </div>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Viewed callback</strong> details
                                </div>
                                <div class="activity-time">5 min ago</div>
                            </div>
                            <div class="activity-details">
                                Spent 3 minutes reviewing callback information
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">MK</div>
                                <span class="user-name">Murtaza Khan</span>
                            </div>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Notes updated</strong>
                                </div>
                                <div class="activity-time">15 min ago</div>
                            </div>
                            <div class="activity-details">
                                Added: "Customer prefers morning calls between 9-11 AM"
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">AR</div>
                                <span class="user-name">Ayesha Rahman</span>
                            </div>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Phone call attempted</strong>
                                </div>
                                <div class="activity-time">1 hour ago</div>
                            </div>
                            <div class="activity-details">
                                Call duration: 0:00 (No answer) - Left voicemail
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">AR</div>
                                <span class="user-name">Ayesha Rahman</span>
                            </div>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Follow-up date set</strong>
                                </div>
                                <div class="activity-time">2 hours ago</div>
                            </div>
                            <div class="activity-change">
                                <span class="change-to">2025-05-25 10:00 AM</span>
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">AR</div>
                                <span class="user-name">Ayesha Rahman</span>
                            </div>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Callback assigned</strong> to Ayesha Rahman
                                </div>
                                <div class="activity-time">3 hours ago</div>
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">SY</div>
                                <span class="user-name">System</span>
                            </div>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-content">
                            <div class="activity-main">
                                <div class="activity-text">
                                    <strong>Callback created</strong>
                                </div>
                                <div class="activity-time">3 hours ago</div>
                            </div>
                            <div class="activity-details">
                                Initial callback created from customer inquiry
                            </div>
                            <div class="activity-user">
                                <div class="user-avatar">AR</div>
                                <span class="user-name">Ayesha Rahman</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script>
        // Tab switching functionality
        document.querySelectorAll('.tab-item').forEach(tab => {
            tab.addEventListener('click', function() {
                // Remove active class from all tabs
                document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
                document.querySelectorAll('.tab-content').forEach(c => c.style.display = 'none');
                
                // Add active class to clicked tab
                this.classList.add('active');
                
                // Show corresponding content
                const index = Array.from(this.parentNode.children).indexOf(this);
                document.querySelectorAll('.tab-content')[index].style.display = 'block';
            });
        });

        // Filter functionality
        document.querySelectorAll('.filter-chip').forEach(chip => {
            chip.addEventListener('click', function() {
                document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
                this.classList.add('active');
                
                // Here you would filter the activity list based on the selected filter
                console.log('Filter by:', this.textContent);
            });
        });

        // Simulate real-time updates
        function addNewActivity() {
            const activityList = document.querySelector('.activity-list');
            const newActivity = document.createElement('div');
            newActivity.className = 'activity-item';
            newActivity.innerHTML = `
                <div class="activity-content">
                    <div class="activity-main">
                        <div class="activity-text">
                            <strong>Viewed callback</strong> details
                        </div>
                        <div class="activity-time">Just now</div>
                    </div>
                    <div class="activity-user">
                        <div class="user-avatar">AR</div>
                        <span class="user-name">Ayesha Rahman</span>
                    </div>
                </div>
            `;
            
            activityList.insertBefore(newActivity, activityList.firstChild);
            
            // Update count
            const countElement = document.querySelector('.activity-count');
            const currentCount = parseInt(countElement.textContent);
            countElement.textContent = currentCount + 1;
        }

        // Simulate activity every 30 seconds (for demo)
        // setInterval(addNewActivity, 30000);
    </script>


    :::DO NOT USE HARDCODED VALUES, USE REAL DATA WHERE POSSIBLE:::