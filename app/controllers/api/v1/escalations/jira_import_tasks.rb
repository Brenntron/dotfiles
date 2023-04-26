module API
  module V1
    module Escalations
      class JiraImportTasks < Grape::API
        include API::V1::Defaults

        resource "escalations/jira_import_tasks" do
          desc "get jira import tasks"
          params do
            use :pagination
          end
          get "", root: :jira_import_tasks do
            std_api_v2 do
              tasks = JiraImportTask.includes(:import_urls).order("imported_at desc").paginate(page: params[:page], per_page: params[:per_page])
              task_array = tasks.map {|m| m.to_hash}
              {data: task_array, total_pages: tasks.total_pages}
            end
          end

          desc "get summary of urls for a task"
          get ":id/submitted_urls", root: :jira_import_tasks do
            std_api_v2 do
              task_id = JiraImportTask.find(params[:id])
              {urls: task_id.import_urls.map {|m| m.to_hash}}
            end
          end

          desc "retry import"
          params do
            requires :task_ids, type: Array[Integer], desc: "ids of the tasks to retry"
          end
          get '/retry_import' do
            std_api_v2 do
              params[:task_ids].each do |id|
                task = JiraImportTask.find(id)
                task.retry
              end
              {status: "Success"}
            end
          end
        end

        resource "escalations/jira_import_tasks/:id/bast_data" do
          desc "get BastApi data for corresponding jira import task"
          get "", root: :jira_import_tasks do
            std_api_v2 do
              task_id = JiraImportTask.find(params[:id]).bast_task
              Bast::Base.get_task_result(task_id)
            end
          end
        end
      end
    end
  end
end

