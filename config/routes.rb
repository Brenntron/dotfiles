Rails.application.routes.draw do

  devise_for :users, controllers: { sessions: 'sessions' }

  root 'pages#index'

  namespace :api do
      get :csrf, to: 'csrf#index'
  end

  mount API::Base => '/api'
  mount GrapeSwaggerRails::Engine => '/documentation'

end
