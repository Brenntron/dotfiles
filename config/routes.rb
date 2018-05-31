Rails.application.routes.draw do

  devise_for :users, controllers: {sessions: 'sessions'}

  namespace :escalations do
    root 'bugs#index'
    resources :bugs do

      member do
        post :create_rules
        post :add_tag
        post :add_whiteboard
        patch :remove_tag
        patch :remove_whiteboard
      end
      resources :references
    end
    namespace :webrep_disputes do
      root 'disputes#index'
      resources :disputes
      get 'tickets', to: 'disputes#index'
      get 'dashboard', to: 'disputes#dashboard'
      get 'research', to: 'disputes#research'
    end


  end

  namespace :admin do
    root 'home#index'
    resources :migrations, only: [:index]
    resources :morsels, only: [:index, :show]
    resources :notes, only: [:index, :edit, :update, :destroy]
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

    namespace :snort_doc do
      root 'root#index'
      get 'doc_output', to: 'rule_docs#doc_output'
      namespace :cves do
        get :nvd
        post :download
        get :missing
        post :update
      end
      get :rule_docs, to: 'rule_docs#index'
      get :upload_docs, to: 'rule_docs#upload'
      post :upload_docs, to: 'rule_docs#send_yaml'
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

  resources :tests

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

  resources :rule_docs
  namespace :templates do
    resources :rules, only: [:show]
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


  namespace :bridge do
    resources :channels, only: [] do
      collection do
        get 'poll-from-bridge/messages', to: 'messages#get_messages'
        post 'fp-event/messages', to: 'messages#messages_from_bridge'
        post 'fp-create/messages', to: 'messages#fp_create'
        post 'rule-file-notify/messages', to: 'messages#rule_file_notify'
      end
      resources :messages, only: [:create]
    end
  end


  mount API::Base => '/api'

end
