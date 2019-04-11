module API
  module V1
    module Escalations
      module FileRep
        class Disputes < Grape::API
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

        end
      end
    end
  end
end
