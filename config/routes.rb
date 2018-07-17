Rails.application.routes.draw do

  resources :rulehit_resolution_mailer_templates
  devise_for :users, controllers: {sessions: 'sessions'}

  namespace :escalations, except: [:destroy, :edit] do
    root 'bugs#index'
    resources :escalation_bugs, controller: 'bugs'
    resources :bugs do
      member do
        # post :create_rules
        post :add_tag
        post :add_whiteboard
        patch :remove_tag
        patch :remove_whiteboard
      end
      # resources :references
    end

    namespace :webcat do
      root 'complaints#index'
      resources :complaints do
        collection do
          get :show_multiple
          get :advanced_search
          get :named_search
          get :standard_search
          get :contains_search
        end
      end
      resources :clusters, only: [:index]
      resources :rules, only: [:index]
      resources :reports, only: [:index]
    end

    namespace :webrep do
      root 'disputes#index'
      resources :disputes, only: [:index, :show] do
        collection do
          get :advanced_search
          get :named_search
          get :standard_search
          get :contains_search
          get :resolution_report
          get :export_per_resolution_report
          get :export_per_engineer_report
          get :resolution_age_report
          get :export_resolution_age_report
        end
      end
      resources :dispute_emails         # TODO This route has no controller so determine if it should be removed.
      resources :dispute_comments       # TODO This route has no controller so determine if it should be removed.
      resources :email_templates        # TODO This route has no controller so determine if it should be removed.

      get 'tickets', to: 'disputes#index'
      get 'dashboard', to: 'disputes#dashboard'
      get 'research', to: 'disputes#research'
    end
  end

  namespace :admin do
    resources :roles
    resources :org_subsets
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

  # TODO some of these named routes need to be rethought to conform to rails conventions
  get 'rules/get_impact' => 'rules#get_impact', format: 'js'
  get 'rules/export' => 'rules#export'
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'


  # resources :rules, param: :sid

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

  resources :research_bugs, controller: 'bugs'
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
        post 'ticket-event/messages', to: 'messages#messages_from_bridge'
        post 'rule-file-notify/messages', to: 'messages#rule_file_notify'
      end
      resources :messages, only: [:create]
    end
  end


  mount API::Base => '/api'

  # Hack to test permissions to Admin page
  if Rails.env.test?
    get '/version', to: 'users#index'
  end

end
