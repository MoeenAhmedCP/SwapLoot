require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Defines the root path route ("/")
  # root "articles#index"
  root to: "home#index"
  mount Sidekiq::Web => '/sidekiq'
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  mount ActionCable.server => '/cable'

  resources :steam_accounts
  resources :inventories, only: [:index]
  resources :notifications, only: [:index, :update]
  resources :selling_filters, only: %i[edit update]
  resources :buying_filters, only: %i[edit update]
  resources :trade_services, only: %i[update]
  resources :trigger_price_cutting, only: %i[update]
  resources :analytics, only: %i[index]
  resources :users
  resources :errors, only: %i[index show]
  resources :sold_items, only: [:index]
  get '/show_api_keys/:id', to: "steam_accounts#show_api_keys", as: "show_api_key"
  get '/edit_api_keys/:id', to: "steam_accounts#edit_api_keys", as: "edit_api_key"
  get '/services', to: "services#index"
  post '/trigger_service', to: "services#trigger_service"
  post '/selling_service', to: "services#selling_service"
  post '/home/update_active_account', to: 'home#update_active_account'
  get '/refresh_balance', to: 'home#refresh_balance', as: 'refresh_balance'
  get '/home/active_trades_reload', to: 'home#active_trades_reload'
  get '/home/reload_item_listed_for_sale', to: 'home#reload_item_listed_for_sale'
  get '/home/fetch_all_steam_accounts', to: 'home#fetch_all_steam_accounts'
  put '/mark_all_as_read', to: 'notifications#mark_all_as_read'
end
