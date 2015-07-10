
Rails.application.routes.draw do

  devise_for :users, controllers: { sessions: 'sessions' }

  resources :events do
    collection {get :send_event}
  end

  root 'bugs#index'

  namespace :api do
      get :csrf, to: 'csrf#index'
  end
  mount API::Base => '/api'
  mount GrapeSwaggerRails::Engine => '/documentation'

end
