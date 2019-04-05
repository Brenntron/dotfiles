Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/escalations/admin', as: 'rails_admin'
  devise_for :users, controllers: {sessions: 'sessions'}

  namespace :escalations, except: [:destroy, :edit] do
    get 'sb_api/query_lookup' => 'sb_api#query_lookup'
    
    resources :rulehit_resolution_mailer_templates, only: [:new, :index, :create, :show, :update, :destroy, :edit]
    resources :sessions, controller: '/sessions', only: [:new, :create, :destroy]

    # TODO These may be reimplemented in the research passenger instance, and then removed from here
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
    end

    namespace :webcat do
      root 'root#index'
      resources :complaints, only: [:index, :show, :update] do
        collection do
          get :show_multiple
          get :advanced_search
          get :named_search
          get :standard_search
          get :contains_search
        end
      end
      resources :complaint_entries do
        collection do
          get :serve_image
        end
      end
      resources :customers, only: :index

      get 'show_multiple', to: 'complaints#show_multiple'
      get 'clusters', to: 'complaints#clusters'

      resources :reports, only: [:index] do
        collection do
          get :index
          get :resolution
          get :export_resolution
          get :complaint_entry
          get :export_complaint_entry
        end
      end
    end

    namespace :webrep do
      root 'root#index'
      resources :disputes, only: [:index, :show] do
        collection do
          # get :advanced_search
          # get :named_search
          # get :standard_search
          # get :contains_search
          get :resolution_report
          get :export_per_resolution_report
          get :export_per_engineer_report
          get :export_per_customer_report
          get :resolution_age_report
          get :export_resolution_age_report
        end
        member do
          get :export
        end
      end
      resources :dispute_emails         # TODO This route has no controller so determine if it should be removed.
      resources :dispute_comments       # TODO This route has no controller so determine if it should be removed.
      resources :email_templates        # TODO This route has no controller so determine if it should be removed.

      get 'dashboard', to: 'disputes#dashboard'
      get 'research', to: 'disputes#research'
    end

    namespace :file_rep do
      root 'root#index'
      resources :disputes, only: [:index, :show]
    end


    resources :users, controller: '/users', only: [:index, :show, :update] do
      resource :bugzilla_api_key, controller: '/bugzilla_api_keys', only: [:edit, :update]

      collection do
        get :results
      end

      # TODO Review metrics for applicability to escalations users
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

    namespace :peake_bridge do
      resources :channels, only: [] do
        collection do
          get 'poll-from-bridge/messages', to: 'messages#get_messages'
          post 'ticket-event/messages', to: 'messages#messages_from_bridge'
          post 'file-rep-create/messages', to: 'file_rep_messages#create'
        end
        resources :messages, only: [:create]
      end
    end
  end #namespace :escalations

  namespace :admin do
    root 'home#index'
    resources :roles, except: [:show]
    resources :org_subsets, except: [:show]
    resources :migrations, only: [:index]
    resources :morsels, only: [:index, :show]
    resources :delayed_jobs, only: [:index]
    resources :notes, only: [:index, :edit, :update, :destroy] do
      member do
        get :related
      end
    end
  end

  resources :events, only: [] do
    collection { get :send_event }
  end

  # TODO some of these named routes need to be rethought to conform to rails conventions
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'


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

  resources :research_bugs, controller: 'bugs'
  resources :bugs, only: [:index, :new, :create, :show, :update] do
    member do
      # post :create_rules
      post :add_tag
      post :add_whiteboard
      patch :remove_tag
      patch :remove_whiteboard
    end
    get :bug_metrics, defaults: { format: :json }
  end


  resources :notes, only: [:create] do
    collection do
      put :publish_to_bugzilla
    end
  end


  mount API::Base => '/escalations/api'

  # Hack to test permissions to Admin page
  if Rails.env.test?
    get '/version', to: 'users#index'
  end

end
