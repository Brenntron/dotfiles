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
            requires :bug_id, type: String, desc: "The connection string"
            requires :job_type, type: String, desc: "is this testing a rule or an attachment"
            optional :attachments, type: String, desc: "The attachemnts to test. this is a list of bugzilla attachment id's"
            optional :rules, type: String, desc: "the rule to test"
          end
        end
        post "", root: "job" do
          if permitted_params[:job][:bug_id]
            options = {
                :attachments       => permitted_params[:job][:attachments],
                :rules          => permitted_params[:job][:rules]
            }.reject() { |k, v| v.nil? }
          else   # (legacy form)

          end
          #do something
        end

      end
    end
  end
end

