Rails.application.routes.draw do

  devise_for :users, controllers: {sessions: 'sessions'}

  namespace :admin do
    root 'home#index'
    resources :migrations, only: [:index]
    resources :morsels, only: [:index, :show]
    resources :rules, only: [:index, :edit, :update] do
      collection do
        get :validations
      end
      member do
        get :related
      end
    end
    resources :reference_types, only: [:index, :edit, :update]
    resources :scheduled_tasks do
      collection do
        post :run_job
      end
    end

    resources :rules_sync, only: [:index] do
      collection do
        get :diagnostics
      end
    end
  end

  resources :events do
    collection { get :send_event }
  end

  namespace :api_test do
    resources :jobs, :defaults => {:format => 'json'}
    resources :pcaps, :defaults => {:format => 'json'}
    resources :engines, :defaults => {:format => 'json'}
    resources :engine_types, :defaults => {:format => 'json'}
    resources :snort_configurations, :defaults => {:format => 'json'}
    resources :rule_configurations, :defaults => {:format => 'json'}
  end

  # some of these named routes need to be rethought to conform to rails conventions
  get 'rules/get_impact' => 'rules#get_impact', format: 'js'
  get 'rules/export' => 'rules#export'
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'


  # resources :rules, param: :sid
  resources :roles
  resources :users do

    collection do
      get :results
    end
    get :status_metrics, defaults: {format: :json}
    get :time_metrics, defaults: {format: :json}
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
      post :create_rules
      post :add_tag
      post :add_whiteboard
      patch :remove_tag
      patch :remove_whiteboard
    end
    resources :references
    get :bug_metrics, defaults: { format: :json }
  end


  resources :notes, only: [:create] do
    collection do
      put :publish_to_bugzilla
    end
  end


  mount API::Base => '/api'

end
