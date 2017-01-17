module API
  module V1
    class Events < Grape::API
      include API::V1::Defaults
      include ActionController::Live
      extend ActiveSupport::Concern

      resource :events do

        desc "get all events"
        params do
          use :pagination
        end
        get "", root: :events do
          events = Event.all.page(params[:page]).per(params[:per_page])
          render events, {meta: {total_pages: events.total_pages}}
        end

        desc "get update progress"
        params do
          requires :description, type: String, desc: "the description"
          requires :user, type:String, desc: "the user whos event this belongs to"
          requires :id,type: String, desc: "the id of the thing we are monitoring"
          optional :action, type: String, desc: "The action"
        end
        get "update-progress" do
          Event.where(description:params["description"],user:params["user"],action:"import_bug:#{params["id"]}").last.progress
        end

        desc "create an event"
        params do
          requires :event, type: Hash do
            requires :action, type: String, desc: "The action"
            optional :user, type: String, desc: "the email of who created the action"
            optional :description, type: String, desc: "additional details about the action"
          end
        end
        post do
          Event.create({
                           user: permitted_params[:event][:user] || current_user.email,
                           action: permitted_params[:event][:action],
                           description: permitted_params[:event][:description] || ""
                       })
          #   push event to clients that are listening for it.
        end
      end
    end
  end
end

