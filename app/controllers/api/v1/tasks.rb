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
            optional :attachment_array, type: Array[String], desc: "The attachments to test. this is a list of bugzilla attachment id's"
            optional :rule_array, type: Array[String], desc: "the rule ids to test"
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
              options[:attachment_array].each do |attachment_id|
                attachment = Attachment.where(id: attachment_id).first
                if /^[-\w]+.pcap$/.match(attachment.file_name)
                  new_task.attachments << attachment
                end
              end
              TestAttachment.send_work_msg(new_task, options, request.headers['Xmlrpc-Token'])
            when "rule"
              options[:rule_array].each do |rule_id|
                new_task.rules << Rule.where(id: rule_id).first unless nil
              end
              TestRule.send_work_msg(new_task,options,request.headers['Xmlrpc-Token'])
            when "commmit"
              SendCommit.send_work_msg(new_task,options,request.headers['Xmlrpc-Token'])
          end
          new_task
        end
      end
    end
  end
end

