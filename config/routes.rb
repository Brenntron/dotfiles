Rails.application.routes.draw do

  devise_for :users, controllers: { sessions: 'sessions' }

  resources :events do
    collection {get :send_event}
  end

  namespace :api_test do
    resources :jobs, :defaults => { :format => 'json' }
    resources :pcaps, :defaults => { :format => 'json' }
    resources :engines, :defaults => { :format => 'json' }
    resources :engine_types, :defaults => { :format => 'json' }
    resources :snort_configurations, :defaults => { :format => 'json' }
    resources :rule_configurations, :defaults => { :format => 'json' }
  end

  get 'rules/add_form' => 'rules#add_form', format: 'js'
  post "bugs/:id/create_rules" => "bugs#create_rules"
  get 'bugs/new' => 'bugs#new'
  post 'bugs' => 'bugs#create'
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'
  delete '/rules' => 'rules#destroy'
  resources 'rules'
  resources 'bugs' do
    resources 'references'
  end

  post '/notes' => 'notes#create'
  put '/notes/publish_to_bugzilla' => 'notes#publish_to_bugzilla'


  mount API::Base => '/api'
  mount GrapeSwaggerRails::Engine => '/documentation'

end
