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
              #authorize!(:manage, Admin)
              unless current_user.has_role?('admin')
                return {:status => 'error', :message => 'you do not have permissions to run this'}.to_json
              end

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

            params do
              requires :path, type: String
              optional :user_arg, type: String
            end

            post "wbrs_call" do
              #begin
                path = permitted_params[:path]
                arg = nil
                arg = permitted_params[:user_arg] unless permitted_params[:user_arg].blank?
                response = WbrsAdminTool.process(path, arg).to_json

                {:status => 'success', :message => response}

              #rescue
              #  {:status => 'error', :message => 'something went fucky'}
              #end


            end

            params do
              requires :id, type: Integer
            end

            post "delete_wbnp_report" do
              wbnp_report = WbnpReport.where(:id => permitted_params[:id]).first

              if wbnp_report.present?
                wbnp_report.destroy
                {:status => 'success', :message => 'report has been obliterated'}
              else
                {:status => 'error', :message => 'report not found'}
              end
            end

            params do
              optional :ids, type: String
              requires :escalation_type, type: String
              optional :all, type: Boolean
            end

            post "sync_collection" do
              ids = []
              if permitted_params[:ids].present?
                permitted_params[:ids].split(",").each do |id|
                  ids << id.strip.to_i
                end
              end
              klass = permitted_params[:escalation_type].constantize
              if permitted_params[:all].present? && permitted_params[:all] == true
                klass.sync_all
                return {:status => "success", :message => "batching sync for all tickets of type #{permitted_params[:escalation_type]} has started"}
              end

              tix = klass.where(:id => ids)
              tix.each do |tic|
                tic.manual_sync
              end

              return {:status => "success", :message => "Syncing specified tickets of type #{permitted_params[:escalation_type]}"}

            end



          end
        end
      end
    end
  end
end
