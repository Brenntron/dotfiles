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
      resources :complaints, only: [:index, :show, :update] do
        collection do
          get :show_multiple
          get :advanced_search
          get :named_search
          get :standard_search
          get :contains_search
        end
      end
      resources :complaint_entries

      get 'show_multiple', to: 'complaints#show_multiple'
      get 'rules', to: 'complaints#rules'

      resources :reports, only: [:index] do
        collection do
          get :index, to: 'complaints#reports'
          get :resolution
          get :export_resolution
        end
      end
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
          get :export_per_customer_report
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
    root 'home#index'
    resources :roles, except: [:show]
    resources :org_subsets, except: [:show]
    resources :migrations, only: [:index]
    resources :morsels, only: [:index, :show]
    resources :notes, only: [:index, :edit, :update, :destroy] do
      member do
        get :related
      end
    end
    resources :rules, only: [:index, :edit, :update] do
      collection do
        get :validations
      end
      member do
        get :related
      end
    end
    resources :reference_types, only: [:index, :edit, :update]
    resources :scheduled_tasks, only: [:index, :show, :create, :destroy] do
      collection do
        post :run_job
      end
    end

    namespace :snort_doc do
      root 'root#index'
      get 'doc_output', to: 'rule_docs#doc_output'
      get :rule_docs, to: 'rule_docs#index'
      get :upload_docs, to: 'rule_docs#upload'
      post :upload_docs, to: 'rule_docs#send_yaml'
      namespace :cves do
        get :nvd
        post :download
        get :missing
        post :update
      end
    end

    resources :rules_sync, only: [:index] do
      collection do
        get :diagnostics
      end
    end
  end

  resources :events, only: [] do
    collection { get :send_event }
  end

  namespace :api_test do
    resources :jobs, only: [:index, :create], :defaults => {:format => 'json'}
    resources :pcaps, only: [:index, :create], :defaults => {:format => 'json'}
    resources :engines, only: [:index], :defaults => {:format => 'json'}
    resources :engine_types, only: [:index], :defaults => {:format => 'json'}
    resources :snort_configurations, only: [:index], :defaults => {:format => 'json'}
    resources :rule_configurations, only: [:index], :defaults => {:format => 'json'}
  end

  # TODO some of these named routes need to be rethought to conform to rails conventions
  get 'rules/get_impact' => 'rules#get_impact', format: 'js'
  get 'rules/export' => 'rules#export'
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'


  # resources :rules, param: :sid

  # resources :tests

  resources :users, only: [:index, :show, :update] do

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
    resources :relationships, only: [:index, :show] do
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
  resources :bugs, only: [:index, :new, :create, :show, :update] do
    member do
      # post :create_rules
      post :add_tag
      post :add_whiteboard
      patch :remove_tag
      patch :remove_whiteboard
    end
    resources :references, only: [:create]
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
