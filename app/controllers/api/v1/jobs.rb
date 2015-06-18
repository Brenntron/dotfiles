module API
  module V1
    class Jobs < Grape::API
      include API::V1::Defaults

      resource :jobs do

        desc "Return a job"
        params do
          requires :id, type: String, desc: "ID of the job"
        end
        get ":id", root: "job" do
          Job.where(id: permitted_params[:id]).first
        end

        desc "Return all jobs"
        params do
          optional :sid, type: String, desc: "SID of the job"
        end
        get "", root: :jobs do
          if permitted_params[:sid]
            Job.where(sid: permitted_params[:sid]).first
          else
            Job.all
          end
        end

        desc "create a job"
        params do
          requires :job, type: Hash do
            requires :bugzilla_id, type: String, desc: "The bug associated with the job"
            requires :job_type, type: String, desc: "is this testing a rule or an attachment"
            requires :current_user, type: Integer, desc: "the user creating the job"
            optional :attachment_array, type: String, desc: "The attachments to test. this is a list of bugzilla attachment id's"
            optional :rule_array, type: String, desc: "the rule ids to test"
          end
        end
        post "", root: "job" do
          if permitted_params[:job][:bugzilla_id]
            options = {
                :bug              => Bug.where(id: permitted_params[:job][:bugzilla_id]).first,
                :job_type         => permitted_params[:job][:job_type],
                :current_user     => User.where(id: permitted_params[:job][:current_user]).first,
                :attachment_array => permitted_params[:job][:attachment_array],
                :rule_array       => permitted_params[:job][:rule_array]
            }.reject() { |k, v| v.nil? }
          else   # (legacy form)

          end
          new_job = Job.create(
              :bug  => options[:bug],
              :job_type     => options[:job_type],
              :user => options[:current_user],
          )
          case options[:job_type]
            when "attachment"
              options[:attachment_array].split(',').each do |attachment_id|
                new_job.attachments << Attachment.where(id: attachment_id).first unless nil
              end
            when "rule"
              options[:rule_array].split(',').each do |rule_id|
                new_job.rules << Rule.where(id: rule_id).first unless nil
              end
          end
          new_job
        end
      end
    end
  end
end

