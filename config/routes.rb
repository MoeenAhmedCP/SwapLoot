Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "home#index"
  resources :steam_accounts
  resources :inventories, only: [:index]
  post '/home/update_active_account', to: 'home#update_active_account'
  get '/refresh_balance', to: 'home#refresh_balance', as: 'refresh_balance'
  get '/home/active_trades_reload', to: 'home#active_trades_reload'
  get '/home/reload_item_listed_for_sale', to: 'home#reload_item_listed_for_sale'
  resources :users, only: [:show]
end
