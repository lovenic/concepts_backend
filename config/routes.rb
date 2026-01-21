Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  mount MissionControl::Jobs::Engine, at: "/jobs"
  get "up" => "rails/health#show", as: :rails_health_check

  # Static pages
  root "static_pages#home"
  get "privacy", to: "static_pages#privacy"
  get "terms", to: "static_pages#terms"
  get "help", to: "static_pages#help"
  get "support", to: "static_pages#help" # Alias for help

  mount_devise_token_auth_for "User", at: "auth", controllers: {
    registrations: "overrides/registrations"
  }

  namespace :api do
    namespace :auth do
      post "apple_sign_in", to: "apple_sign_in#create"
    end
    resources :categories, only: [:index]
    resources :feed, only: [:index] do
      collection do
        post :generate
      end
    end
    resources :pinned, only: [:index]
    resources :concepts, only: [:show] do
      member do
        post :like
        post :pin
      end
    end
    patch "users/update_timezone", to: "users#update_timezone"
    resources :subscriptions, only: [:create]
    resources :push_tokens, only: [:create]
    delete "/accounts", to: "accounts#destroy"
  end
end
