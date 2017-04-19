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

  # some of these named routes need to be rethought to conform to rails conventions
  # get 'rules/add_form' => 'rules#add_form', format: 'js'
  get 'rules/get_impact' => 'rules#get_impact', format: 'js'
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'
  delete '/rules' => 'rules#destroy'


  # resources :rules, param: :sid

  resources :users do
    collection do
      get :results
    end
    get :status_metrics, defaults: { format: :json }
    get :time_metrics, defaults: { format: :json }
    get :pending_team_metrics, defaults: {format: :json}
    get :resolved_team_metrics, defaults: {format: :json}
    get :time_team_metrics, defaults: {format: :json}
    get :component_team_metrics, defaults: {format: :json}
    patch :add_to_team
    patch :remove_from_team
    resources :relationships do
      collection do
        get :member_status
      end
    end
  end
  resources :bugs do
    member do
      post  :create_rules
      post  :add_tag
      patch :remove_tag
    end
    resources :references
  end

  namespace :rule_sync do
    resources :rule_files, only: [:create, :new]
    resources :diags, only: [:index]
  end


  post '/notes' => 'notes#create'
  put '/notes/publish_to_bugzilla' => 'notes#publish_to_bugzilla'


  mount API::Base => '/api'
  mount GrapeSwaggerRails::Engine => '/documentation'

end
