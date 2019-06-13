module API
  module V1
    module Escalations
      module FileRep
        class Disputes < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession
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

            desc 'Create a File Rep Dispute through the form'
            params do
              requires :shas_array, type: Array[String], desc: 'SHA256 hash of the file'
              requires :disposition_suggested, type: String, desc: 'Suggested disposition'
              requires :assignee, type: String, desc: 'Assignee'
              # requires :shas_input_type, type: String, desc: 'Input type' This will be implemented later when analysts can upload files
            end
            post "form" do
              std_api_v2 do
                duplicates = []
                uniques = []
                user_validation = User.where(cvs_username: params[:assignee])

                if user_validation.exists?
                  permitted_params['shas_array'].each do |sha256|
                    check_for_duplicate = FileReputationDispute.where(sha256_hash: sha256).where.not(status: FileReputationDispute::STATUS_RESOLVED).count

                    if check_for_duplicate == 0
                      FileReputationDispute.create_through_form(bugzilla_rest_session,
                                                                sha256,
                                                                params[:disposition_suggested],
                                                                params[:assignee])
                      uniques << sha256
                    else
                      duplicates << sha256
                    end
                  end

                  if duplicates.any? && uniques.any?
                    raise "The following SHA256 hashes were created successfully: " + uniques.join(', ').to_s +
                    "@newline The following SHA256 hashes were duplicates and were not created: " + duplicates.join(', ').to_s
                  elsif duplicates.any? && !uniques.any?
                    raise "The following SHA256 hashes were duplicates and were not created: " + duplicates.join(', ').to_s
                  end
                else
                  raise "Invalid assignee or assignee does not exist. Please try again."
                end

                render json: {status: 'Success'}
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

            desc 'Update File Rep Dispute status'
            params do
              requires :dispute_ids, type: Array[String]
              requires :status, type: String
              optional :resolution, type: String
              optional :comment, type: String
            end

            post "set_disputes_status" do
              std_api_v2 do
                authorize!(:update, FileReputationDispute)
                dispute_ids = params[:dispute_ids].map{|id| id.to_i}
                status = params[:status]
                resolution = ""
                comment = ""

                if params[:resolution].present?
                  resolution = params[:resolution]
                else
                  resolution = nil
                end

                if params[:comment].present?
                  if status == 'RESOLVED_CLOSED'
                    comment = status + ' : ' + resolution + ' - ' + params[:comment]
                  else
                    comment = status + ' - ' + params[:comment]
                  end
                end

                file_rep_disputes = FileReputationDispute.where(id: dispute_ids)

                file_rep_disputes.each do |dispute|
                  dispute.update_status(status)

                  if comment.present?
                    FileRepComment.create!(comment: comment, file_reputation_dispute_id: dispute.id, user_id: current_user.id)
                  end

                  if resolution.present?
                    dispute.update(resolution: resolution)
                  end
                end

                render json: {status: 'Success'}
              end
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

                assignee = User.find(params[:new_assignee]).cvs_username

                disputes = FileReputationDispute.assign(params[:dispute_ids], user: params[:new_assignee])
                if params[:dispute_ids].length == 1 && disputes.length == 0
                  raise ('The selected dispute ticket is already assigned')
                elsif params[:dispute_ids].length > 1 && disputes.length == 0
                  raise ('The selected dispute tickets are already assigned')
                end
                {:status => "success", :data => disputes, :assignee => assignee}.to_json
              end
            end
          end
        end
      end
    end
  end
end
