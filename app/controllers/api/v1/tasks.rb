module API
  module V1
    class Tasks < Grape::API
      include API::V1::Defaults

      resource :tasks do

        desc "Return a task"
        params do
          requires :id, type: String, desc: "ID of the task"
        end
        get ":id", root: "task" do
          Task.where(id: permitted_params[:id]).first
        end

        desc "Return all tasks"
        params do
          optional :sid, type: String, desc: "SID of the task"
        end
        get "", root: :tasks do
          if permitted_params[:sid]
            Task.where(sid: permitted_params[:sid]).first
          else
            Task.all
          end
        end

        desc "create a task"
        params do
            requires :task, type: Hash do
            requires :bugzilla_id, type: String, desc: "The bug associated with the task"
            requires :task_type, type: String, desc: "is this testing a rule or an attachment"
            requires :created_by, type: Integer, desc: "the user creating the task"
            optional :attachment_array, type: String, desc: "The attachments to test. this is a list of bugzilla attachment id's"
            optional :rule_array, type: String, desc: "the rule ids to test"
          end
        end
        post "", root: "task" do
          if permitted_params[:task][:bugzilla_id]
            options = {
                :bug              => Bug.where(id: permitted_params[:task][:bugzilla_id]).first,
                :task_type         => permitted_params[:task][:task_type],
                :current_user     => User.where(id: permitted_params[:task][:created_by]).first,
                :attachment_array => permitted_params[:task][:attachment_array],
                :rule_array       => permitted_params[:task][:rule_array]
            }.reject() { |k, v| v.nil? }
          else   # (legacy form)
          end
          new_task = Task.create(
              :bug  => options[:bug],
              :task_type     => options[:task_type],
              :user => options[:current_user],
          )
          case options[:task_type]
            when "attachment"
              options[:attachment_array].split(',').each do |attachment_id|
                new_task.attachments << Attachment.where(id: attachment_id).first unless nil
              end
              PublishAttachment.send_work_msg(new_task,options,request)
            when "rule"
              options[:rule_array].split(',').each do |rule_id|
                new_task.rules << Rule.where(id: rule_id).first unless nil
              end
              PublishRule.send_work_msg(new_task,options,request)
          end
          new_task
        end
      end
    end
  end
end

