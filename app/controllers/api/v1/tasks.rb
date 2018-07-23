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
          authorize!(:show, Task)
          Task.where(id: permitted_params[:id]).first
        end

        desc "Return all tasks"
        params do
          optional :sid, type: String, desc: "SID of the task"
        end
        get "", root: :tasks do
          authorize!(:index, Task)
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
          begin
            authorize!(:create, Task)
            new_task = nil
            if permitted_params[:task][:bugzilla_id]
              options = {
                  :bug              => Bug.where(id: permitted_params[:task][:bugzilla_id]).first,
                  :task_type         => permitted_params[:task][:task_type],
                  :current_user     => User.where(id: permitted_params[:task][:created_by]).first,
                  :attachment_array => permitted_params[:task][:attachment_array],
                  :rule_array       => permitted_params[:task][:rule_array]
              }.reject() { |k, v| v.nil? }
              raise Exception.new("Bug has no attachments to test against.") if options[:bug].attachments.empty?
              case options[:task_type]
                when "attachment"
                  if options[:attachment_array].any?
                    new_task = Task.create_pcap_test(permitted_params[:task][:bugzilla_id],
                                                     permitted_params[:task][:created_by])
                    TestAttachment.new(new_task, request.headers['Xmlrpc-Token'], options[:attachment_array]).send_work_msg
                  end
                when "rule"
                  if options[:rule_array].any?
                    new_task = Task.create_rule_test(permitted_params[:task][:bugzilla_id],
                                                     permitted_params[:task][:created_by])
                    TestRule.new(new_task, request.headers['Xmlrpc-Token'], options[:bug], options[:rule_array]).send_work_msg
                  end
              end
            end
            new_task
          rescue Exception => e
            throw :error,
                  status: 418,
                  message: e.message
          end
        end
      end
    end
  end
end

