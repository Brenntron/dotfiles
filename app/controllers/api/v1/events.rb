module API
  module V1
    class Events < Grape::API
      include API::V1::Defaults

      resource :events do

        desc "get all events"
        params do
          use :pagination
        end
        get "", root: :events do
          events = Event.all.page(params[:page]).per(params[:per_page])
          render events, {meta: {total_pages: events.total_pages}}
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
        end
      end
    end
  end
end
