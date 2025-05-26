Rails.application.routes.draw do
  resources :refunds, only: [:index, :show, :update]
  # Orders routes
  resources :orders do
    member do
      get :get_callback
    end
  end
  
  # Test broadcast route
  get "test_broadcast", to: "orders#test_broadcast"
  
  # Dispatches routes  
  resources :dispatches
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount ActionCable server
  mount ActionCable.server => '/cable'

  # Dashboard route
  get "dashboard", to: "dashboard#index"

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
