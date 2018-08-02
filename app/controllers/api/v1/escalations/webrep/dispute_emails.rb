module API
  module V1
    module Escalations
      module Webrep
        class DisputeEmails < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/dispute_emails" do

            desc "get a dispute email"
            params do
              requires :id, type: String, desc: "ID of the dispute email"
            end

            get ":id", root: "dispute_email" do
              authorize!(:show, DisputeEmail)
              DisputeEmail.where(id: permitted_params[:id])
            end

            desc "edit a dispute email"
            params do
              requires :id, type: Integer, desc: "The dispute email's id in the database."
              optional :status, type: String, desc: "The read or unread status of email."
            end

            put ":id", root: "dispute_email" do
              authorize!(:update, DisputeEmail)
              @dispute_email = DisputeEmail.find(permitted_params[:id])
              authorize!(:update, @dispute_email)
              @dispute_email.update_attributes(status: permitted_params[:status])

              {email: @dispute_email, attachments: @dispute_email.dispute_email_attachments}
            end

            desc "create a dispute email"
            params do
              requires :dispute_id, type: Integer, desc: "The id of the dispute the email should be linked to"
              requires :to, type: String, desc: "The email address the email is send to"
              requires :body, type: String, desc: "The body of the email"
              requires :subject, type: String, desc: "The subject of the email"
              optional :dispute_email_id, type: Integer, desc: "The ID of the dispute email being replied to"
              optional :from, type: String, desc: "The email address the email is from"
              optional :attachments, type: Hash, desc: "File attachments"
            end

            post "", root: "dispute_email" do
              authorize!(:create, DisputeEmail)
              begin
                #temporary, for development, don't wanna be sending these to actual customers
                params[:to] = "claclair@cisco.com"


                new_email = DisputeEmail.create_email_and_send(params, bugzilla_session, current_user)

                if params[:dispute_email_id].present?
                  replied_email = DisputeEmail.where(:id => params[:dispute_email_id]).first
                  replied_email.status = DisputeEmail::REPLIED
                  replied_email.save
                end

                if params[:dispute_id].present?
                  dispute = Dispute.find(params[:dispute_id])
                  unless dispute.case_responded_at
                    dispute.update!(case_responded_at: Time.now)
                  end
                end

                return ""
              rescue Exception => e
                Rails.logger.error e
                raise "There was an error in attempting to send an email."
              end

            end

            desc "create a general email"
            params do
              requires :to, type: String, desc: "The email address the email is send to"
              requires :body, type: String, desc: "The body of the email"
              requires :subject, type: String, desc: "The subject of the email"
              optional :from, type: String, desc: "The email address the email is from"
              optional :attachments, type: Hash, desc: "File attachments"
            end

            post "ad_hoc", root: "dispute_email" do
              authorize!(:create, DisputeEmail)
              begin
                ActiveRecord::Base.transaction do

                  #extra precaution to make *sure* goofy test emails doesn't slip off to an actual customer when using 'realistic' data
                  if Rails.env == "development"
                    params[:to] = current_user.email
                  end

                  email_info = EscalationEmailTool.generate_email_info(params, current_user)

                  conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence')
                  conn.post(email_info[:email_args], email_info[:attachments_to_mail])

                  return ""
                end
              rescue Exception => e
                Rails.logger.error e
                raise "There was an error in attempting to send an email."
              end
            end

          end
        end
      end
    end
  end
end
