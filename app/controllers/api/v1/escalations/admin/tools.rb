module API
  module V1
    module Escalations
      module Admin
        class Tools < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession

          resource "escalations/admin/tools" do
            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end
            desc 'execute task'
            params do
              requires :task, type: String
              optional :args, type: String
            end

            post "execute_task" do
              authorize!(:manage, Admin)

              task = permitted_params[:task]
              args = permitted_params[:args]

              if !AdminTask.available_tasks.include?(task.to_sym)
                return {:status => 'error', :message => "provided invalid task"}.to_json
              end

              if args.present?
                begin
                  args_hash = JSON.parse(args)
                rescue JSON::ParserError
                  return {:status => 'error', :message => "your arguments' json format sucks"}.to_json 
                end  
              end 

              morsel = AdminTask.execute_task(task, args)

              {:status => 'success', :morsel_id => morsel.id}.to_json

            end

          end
        end
      end
    end
  end
end
