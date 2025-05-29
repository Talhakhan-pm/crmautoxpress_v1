Rails.application.routes.draw do
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
    end
  end
  
  # Refunds routes
  resources :refunds do
    collection do
      get :sla_analytics
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

  # Callbacks routes  
  resources :callbacks
  resources :agent_callbacks, only: [:show]
  
  # Customers routes (minimal - no new/create)
  resources :customers, only: [:index, :show, :edit, :update]
  
  # Products routes (view-only catalog, auto-created from callbacks)
  resources :products, only: [:index, :show, :edit, :update]

  # Defines the root path route ("/")
  root "dashboard#index"
end
