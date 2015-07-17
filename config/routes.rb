
Rails.application.routes.draw do

  devise_for :users, controllers: { sessions: 'sessions' }

  resources :events do
    collection {get :send_event}
  end

  root 'pages#index'

  mount API::Base => '/api'
  mount GrapeSwaggerRails::Engine => '/documentation'

end
