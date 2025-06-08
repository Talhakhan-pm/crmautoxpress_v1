Rails.application.routes.draw do
  # Email actions
  post 'email_actions/send_order_email', to: 'email_actions#send_order_email'
  # Notification routes
  patch 'notifications/:id/mark_read', to: 'notifications#mark_read', as: :mark_notification_read
  patch 'notifications/mark_all_read', to: 'notifications#mark_all_read', as: :mark_all_notifications_read
  # Suppliers routes (view-only catalog, auto-created from orders)
  resources :suppliers, only: [:index, :show, :edit, :update]
  # Orders routes
  resources :orders do
    member do
      get :get_callback
      get :get_order_details
    end
  end
  
  # Test broadcast route
  get "test_broadcast", to: "orders#test_broadcast"
  
  # Dispatches routes  
  resources :dispatches do
    member do
      patch :retry_dispatch
      post :create_replacement_order
      patch :process_full_refund
      patch :cancel_with_reason
      patch :contact_customer_delay
      patch :contact_customer_price_increase
      # Resolution-specific variants
      patch :retry_dispatch_from_resolution
      post :create_replacement_order_from_resolution
      patch :process_full_refund_from_resolution
    end
  end
  
  # Refunds routes
  resources :refunds do
    collection do
      get :sla_analytics
      get :sla_alerts_dashboard
      get :returns_tracking
      post :create_refund, to: 'refunds#create'
      post :bulk_escalate
      post :bulk_prioritize
    end
    member do
      patch :process_refund
      patch :cancel_refund
      post :create_replacement
      patch :refund_full_amount
    end
  end
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable server
  mount ActionCable.server => '/cable'

  # Dashboard route
  get "dashboard", to: "dashboard#index"
  
  # Resolution Queue Dashboard
  get "resolution", to: "resolution#index"
  patch "resolution/:id/stage", to: "resolution#update_stage", as: :update_resolution_stage
  patch "resolution/:id/notes", to: "resolution#update_notes", as: :update_resolution_notes
  post "resolution/:id/retry", to: "resolution#dispatcher_retry", as: :resolution_dispatcher_retry
  post "resolution/:id/alternative", to: "resolution#dispatcher_alternative", as: :resolution_dispatcher_alternative
  post "resolution/:id/replacement", to: "resolution#create_replacement_order", as: :resolution_create_replacement
  
  # Communication Hub routes
  get "resolution/:id/conversation", to: "resolution#conversation", as: :resolution_conversation
  post "resolution/:id/message", to: "resolution#send_message", as: :resolution_send_message
  patch "resolution/:id/mark_viewed", to: "resolution#mark_viewed", as: :resolution_mark_viewed
  
  # Quick Action routes
  patch "resolution/:id/mark_clarified", to: "resolution#mark_clarified", as: :resolution_mark_clarified
  patch "resolution/:id/request_info", to: "resolution#request_info", as: :resolution_request_info
  patch "resolution/:id/escalate", to: "resolution#escalate", as: :resolution_escalate
  
  # Stage Toggle routes
  patch "resolution/:id/move_to_agent_review", to: "resolution#move_to_agent_review", as: :resolution_move_to_agent_review
  patch "resolution/:id/move_to_dispatcher_review", to: "resolution#move_to_dispatcher_review", as: :resolution_move_to_dispatcher_review
  patch "resolution/:id/approve_retry", to: "resolution#approve_retry", as: :resolution_approve_retry
  patch "resolution/:id/suggest_alternative", to: "resolution#suggest_alternative", as: :resolution_suggest_alternative
  patch "resolution/:id/approve_refund", to: "resolution#approve_refund", as: :resolution_approve_refund
  patch "resolution/:id/customer_approved", to: "resolution#customer_approved", as: :resolution_customer_approved
  patch "resolution/:id/customer_declined", to: "resolution#customer_declined", as: :resolution_customer_declined
  patch "resolution/:id/follow_up", to: "resolution#follow_up", as: :resolution_follow_up
  
  # New Dispatcher Sourcing Actions
  patch "resolution/:id/accept_delay", to: "resolution#accept_delay", as: :resolution_accept_delay
  patch "resolution/:id/request_price_increase", to: "resolution#request_price_increase", as: :resolution_request_price_increase
  patch "resolution/:id/send_compatible_alternative", to: "resolution#send_compatible_alternative", as: :resolution_send_compatible_alternative
  patch "resolution/:id/dispatcher_refund", to: "resolution#dispatcher_refund", as: :resolution_dispatcher_refund
  
  # Return Resolution Actions
  patch "resolution/:id/authorize_return_and_refund", to: "resolution#authorize_return_and_refund", as: :resolution_authorize_return_and_refund
  patch "resolution/:id/authorize_return_and_replacement", to: "resolution#authorize_return_and_replacement", as: :resolution_authorize_return_and_replacement
  patch "resolution/:id/generate_return_label", to: "resolution#generate_return_label", as: :resolution_generate_return_label
  patch "resolution/:id/mark_return_shipped", to: "resolution#mark_return_shipped", as: :resolution_mark_return_shipped
  patch "resolution/:id/mark_return_received", to: "resolution#mark_return_received", as: :resolution_mark_return_received
  patch "resolution/:id/complete_refund", to: "resolution#complete_refund", as: :resolution_complete_refund

  # Callbacks routes  
  resources :callbacks do
    collection do
      get :dashboard
    end
    member do
      post :track_call
    end
    resources :communications, only: [:create, :destroy]
  end
  
  resources :agent_callbacks, only: [:show] do
    resources :communications, only: [:create, :destroy]
  end
  
  # Customers routes (minimal - no new/create)
  resources :customers, only: [:index, :show, :edit, :update]
  
  # Products routes (view-only catalog, auto-created from callbacks)
  resources :products, only: [:index, :show, :edit, :update]

  # Defines the root path route ("/")
  root "dashboard#index"
end
