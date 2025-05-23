module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :activities, as: :trackable, dependent: :destroy
    after_update :track_changes, if: :saved_changes?
    after_create :track_creation
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
end