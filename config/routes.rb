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
  get 'rules/add_form' => 'rules#add_form', format: 'js'
  post "sessions/create" => "sessions#create"
  post "/attachments" => "attachments#create"
  root 'pages#index'
  delete '/rules' => 'rules#destroy'


  resources :rules
  resources :users do
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


  post '/notes' => 'notes#create'
  put '/notes/publish_to_bugzilla' => 'notes#publish_to_bugzilla'


  mount API::Base => '/api'
  mount GrapeSwaggerRails::Engine => '/documentation'

end
