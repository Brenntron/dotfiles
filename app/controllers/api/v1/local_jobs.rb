module API
  module V1
    class LocalJobs < Grape::API
      include API::V1::Defaults

      resource :local_jobs do

        desc "Return a local job"
        params do
          requires :id, type: String, desc: "ID of the local job"
        end
        get ":id", root: "local_job" do
          LocalJob.where(id: permitted_params[:id]).first
        end

        desc "Return all local jobs"
        params do
          optional :sid, type: String, desc: "SID of the local job"
        end
        get "", root: :local_jobs do
          if permitted_params[:sid]
            LocalJob.where(sid: permitted_params[:sid]).first
          else
            LocalJob.all
          end
        end

        desc "create a local job"
        params do
            requires :local_job, type: Hash do
            requires :bugzilla_id, type: String, desc: "The bug associated with the job"
            requires :job_type, type: String, desc: "is this testing a rule or an attachment"
            requires :created_by, type: Integer, desc: "the user creating the job"
            optional :attachment_array, type: String, desc: "The attachments to test. this is a list of bugzilla attachment id's"
            optional :rule_array, type: String, desc: "the rule ids to test"
          end
        end
        post "", root: "local_job" do

          if permitted_params[:local_job][:bugzilla_id]
            options = {
                :bug              => Bug.where(id: permitted_params[:local_job][:bugzilla_id]).first,
                :job_type         => permitted_params[:local_job][:job_type],
                :current_user     => User.where(id: permitted_params[:local_job][:current_user]).first,
                :attachment_array => permitted_params[:local_job][:attachment_array],
                :rule_array       => permitted_params[:local_job][:rule_array]
            }.reject() { |k, v| v.nil? }

          else   # (legacy form)

          end

          new_job = LocalJob.create(
              :bug  => options[:bug],
              :job_type     => options[:job_type],
              :user => options[:current_user],
          )

          case options[:job_type]
            when "attachment"
              options[:attachment_array].split(',').each do |attachment_id|
                new_job.attachments << Attachment.where(id: attachment_id).first unless nil
              end
              PublishAttachment.send_work_msg(new_job,options,request)
            when "rule"
              options[:rule_array].split(',').each do |rule_id|
                new_job.rules << Rule.where(id: rule_id).first unless nil
              end
              PublishRule.send_work_msg(new_job,options,request)
          end
          new_job
        end
      end
    end
  end
end

