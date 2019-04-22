module API
  module V1
    module Escalations
      module FileRep
        class Disputes < Grape::API
          resource "escalations/file_rep/disputes" do

            desc 'Create a File Rep Dispute'
            params do
              requires :sha256_hash, type: String, desc: 'SHA256 hash of the file'
              requires :file_name, type: String, desc: 'Name of the file'
              requires :file_size, type: Integer, desc: 'File size'
              requires :sample_type, type: String, desc: 'Sample type'
              requires :disposition_suggested, type: String, desc: 'What should the disposiiton be'
              requires :platform, type: String, desc: 'Platform'
              requires :sha256_checksum, type: String, desc: 'SHA256 checksum'
            end
            post "" do
              std_api_v2 do
                dispute = FileReputationDispute.create_action(bugzilla_rest_session,
                                                              params[:sha256_hash],
                                                              params[:file_name],
                                                              params[:file_size],
                                                              params[:sample_type],
                                                              params[:disposition_suggested],
                                                              "ACE",
                                                              params[:platform],
                                                              params[:sha256_checksum]
                                                              )
                render json: {status: 'Success', case_id: dispute.id}
              end
              end

            desc 'Edit a FileRep Dispute'
            params do
              requires :id, type: Integer
              optional :customer_id, type: Integer
              optional :status, type: String
              optional :source, type: String
              optional :platform, type: String
              optional :description, type:String
              optional :file_name, type: String
              optional :sha256_hash, type: String, desc: "SHA256 hash"
              optional :sample_type, type: String
              optional :disposition, type: String
              optional :disposition_suggested, type: String
            end
            put ":id" do
              # This might change slightly depending on how we are going to package parameters to send to this Grape API controller
              filerep_dispute = FileReputationDispute.find(params[:id])

              filerep_dispute.customer_id = permitted_params[:customer_id]
              filerep_dispute.status = permitted_params[:customer_id]
              filerep_dispute.source = permitted_params[:customer_id]
              filerep_dispute.platform = permitted_params[:customer_id]
              filerep_dispute.description = permitted_params[:customer_id]
              filerep_dispute.file_name = permitted_params[:customer_id]
              filerep_dispute.sha256_hash = permitted_params[:customer_id]
              filerep_dispute.sample_type = permitted_params[:customer_id]
              filerep_dispute.disposition = permitted_params[:customer_id]
              filerep_dispute.disposition_suggested = permitted_params[:customer_id]

              filerep_dispute.save!

              filerep_dispute.to_json
            end

            desc 'Inline Take FileRep Dispute'
            params do
              requires :dispute_id, type: Integer
            end
            patch 'take_dispute/:dispute_id' do
              std_api_v2 do
                authorize!(:update, FileReputationDispute)

                dispute_id = permitted_params['dispute_id']
                FileReputationDispute.take_tickets(dispute_id, user: current_user)

                { username: current_user.cvs_username, dispute_ids: dispute_id }
              end
            end

            desc 'Inline Return FileRep Dispute'
            params do
              requires :dispute_id, type: Integer
            end
            patch 'return_dispute/:dispute_id' do
              std_api_v2 do
                authorize!(:update, FileReputationDispute)

                dispute_id = permitted_params['dispute_id']
                FileReputationDispute.find(dispute_id).return_dispute

                { username: current_user.cvs_username, dispute_id: dispute_id }
              end
            end

            desc 'Take FileRep Disputes'
            params do
              requires :dispute_ids, type: Array[Integer]
            end
            patch 'take_disputes' do
              std_api_v2 do
                authorize!(:update, FileReputationDispute)

                dispute_ids = permitted_params['dispute_ids']
                FileReputationDispute.take_tickets(dispute_ids, user: current_user)

                { username: current_user.cvs_username, dispute_ids: dispute_ids }
              end
            end

            desc 'Change FileRep Dispute assignee'
            params do
              requires :dispute_ids, type: Array[Integer]
              requires :new_assignee, type: String
            end
            post 'change_assignee' do
              std_api_v2 do
                authorize!(:update, FileReputationDispute)

                disputes = FileReputationDispute.assign(params[:dispute_ids], user: params[:new_assignee])

                if disputes.length == 0
                  raise ('The selected dispute tickets are already assigned.')
                end
                {:status => "success", :data => disputes}.to_json
              end
            end

          end
        end
      end
    end
  end
end
