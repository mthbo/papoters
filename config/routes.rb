Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  mount Attachinary::Engine => "/attachinary"

  mount ActionCable.server => '/cable'

  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, lambda { |u| u.admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users,
    only: :omniauth_callbacks,
    controllers: {
      omniauth_callbacks: 'users/omniauth_callbacks'
    }

  scope '(:locale)', locale: /#{I18n.available_locales.join("|")}/ do

    devise_for :users,
      skip: :omniauth_callbacks,
      controllers: {
        registrations: 'users/registrations',
        confirmations: 'users/confirmations',
        passwords: 'users/passwords'
      }

    devise_scope :user do
      get "users/confirm", to: "users/registrations#confirm"
      get "users/password/reset", to: "users/passwords#reset"
    end

    resources :users, only: [:show]
    get '/dashboard', to: 'users#dashboard'
    get '/stripe_connection', to: 'users#stripe_connection'
    patch '/change_locale', to: 'users#change_locale'
    get '/country', to: 'users#country'
    patch '/update_country', to: 'users#update_country'

    root to: 'pages#home'
    get '/advisor', to: 'pages#advisor'
    get '/about', to: 'pages#about'

    resources :offers, only: [:show, :new, :create, :edit, :update], shallow: true do
      resources :deals, only: [:show, :new, :create], path: 'sessions' do
        member do
          get 'proposition', to: 'deals#proposition'
          get 'review', to: 'deals#review'
          patch 'save_proposition', to: 'deals#save_proposition'
          patch 'submit_proposition', to: 'deals#submit_proposition'
          patch 'decline_proposition', to: 'deals#decline_proposition'
          patch 'accept_proposition', to: 'deals#accept_proposition'
          patch 'complete', to: 'deals#complete'
          patch 'save_review', to: 'deals#save_review'
          patch 'disable_messages', to: 'deals#disable_messages'
          patch 'cancel', to: 'deals#cancel'
        end
        resources :objectives, only: [:create, :update, :destroy]
        resources :messages, only: [:create]
        resources :payments, only: [:create]
      end
      member do
        post 'pin', to: 'offers#pin'
      end
    end

  end

end
