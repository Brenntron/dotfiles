Rails.application.routes.draw do


  devise_for :users, controllers: {sessions: 'sessions'}

  namespace :escalations, except: [:destroy, :edit] do
    get 'admin/extras' => 'admin#index'

    resources :roles, except: [:show], controller: '/admin/roles'

    resources :rulehit_resolution_mailer_templates, only: [:new, :index, :create, :show, :update, :destroy, :edit]
    resources :sessions, controller: '/sessions', only: [:new, :create, :destroy]

    # TODO These may be reimplemented in the research passenger instance, and then removed from here
    root '/pages#index'

    namespace :other_admin_tools do
      root 'tools#index'
      get 'tasks', to: 'tools#tasks'
      get 'rule_api', to: 'tools#rule_api'
      get 'reptool', to: 'tools#reptool'
      get 'wbnp_reports', to: 'tools#wbnp_reports'
      get 'wbnp_report/:id', to: 'tools#wbnp_report'
      get 'manage_escalations_sync', to: 'tools#manage_escalations_sync'
      get 'status_api', to: 'tools#status_api'
      get 'console', to: 'tools#rails_c'

      mount DelayedJobWeb, at: "delayed_job"
      match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
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
          get :resolution_message_templates
        end
      end
      resources :complaint_entries, only: [:index, :show, :update] do
        collection do
          get :serve_image
        end
      end
      resources :customers, only: :index

      get 'resolution_message_templates', to: 'complaints#resolution_message_templates'
      get 'show_multiple', to: 'complaints#show_multiple'
      get 'clusters', to: 'complaints#clusters'
      get 'research', to: 'complaints#research'

      get 'csam_reports', to: 'complaints#csam_reports'

      resources :reports, only: [:index] do
        collection do
          get :index
          get :old_resolution
          get :resolution
          get :export_resolution
          get :complaint_entry
          get :export_complaint_entry
        end
      end

      resources :jira_import_tasks, only: [:index]

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
          get 'download_email_attachment_file/:id', to: 'disputes#download_email_attachment_file'
          get :resolution_message_templates
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
      get 'resolution_message_templates' => 'disputes#resolution_message_templates'
      get :export_selected_dispute_rows, to: 'disputes#export_selected_dispute_rows'
      get :export_selected_dispute_entry_rows, to: 'disputes#export_selected_dispute_entry_rows'
    end

    namespace :sdr do
      root 'root#index'
      resources :disputes, only: [:index, :show] do
        collection do
          get 'download_sdr_attachment_file/:id', to: 'disputes#download_sdr_attachment_file'
        end
        get :all_attachments
        get :resolution_message_templates
      end
      get 'resolution_message_templates' => 'disputes#resolution_message_templates'
    end

    namespace :file_rep do
      root 'disputes#index'
      resources :disputes, only: [:index, :show] do
        get :resolution_message_templates, on: :collection
      end

      get 'naming_guide', to: 'disputes#naming_guide'
      get 'sandbox-html-report', to: 'disputes#sandbox_html_report'
      get 'resolution_message_templates' => 'disputes#resolution_message_templates'

    end

    resources :users, controller: '/users', only: [:index, :show, :update] do

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
  mount RailsAdmin::Engine => '/escalations/admin', as: 'rails_admin'
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
  mount API::Base => '/escalations/api'

end
