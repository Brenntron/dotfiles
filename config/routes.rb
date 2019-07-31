Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/escalations/admin', as: 'rails_admin'
  devise_for :users, controllers: {sessions: 'sessions'}

  namespace :escalations, except: [:destroy, :edit] do
    get 'sb_api/query_lookup' => 'sb_api#query_lookup'

    resources :roles, except: [:show], controller: '/admin/roles'

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

    namespace :other_admin_tools do
      root 'tools#index'
      get 'tasks', to: 'tools#tasks'
      get 'rule_api', to: 'tools#rule_api'
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
      get :export_selected_dispute_rows, to: 'disputes#export_selected_dispute_rows'
      get :export_selected_dispute_entry_rows, to: 'disputes#export_selected_dispute_entry_rows'
    end

    namespace :file_rep do
      root 'disputes#index'
      resources :disputes, only: [:index, :show]
      get 'sandbox-html-report', to: 'disputes#sandbox_html_report'
    end


    resources :users, controller: '/users', only: [:index, :show, :update] do
      resource :bugzilla_api_key, controller: '/bugzilla_api_keys', only: [:edit, :update]

      collection do
        get :all
      end

      collection do
        get :results
      end

      patch :add_to_team
      patch :remove_from_team
      resources :relationships, controller: '/relationships', only: [:index, :show] do
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

  root 'pages#index'
  mount API::Base => '/escalations/api'

end
