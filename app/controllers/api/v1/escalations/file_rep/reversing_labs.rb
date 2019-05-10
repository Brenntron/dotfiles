module API
  module V1
    module Escalations
      module FileRep
        class ReversingLabs < Grape::API
          resource "escalations/filerep/reversing_labs" do

            desc 'Make an API call to Reversing Labs to get all data about a SHA256'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/:sha256_hash" do
              sha256_hash = params[:sha256_hash]
              api_response = FileReputationApi::ReversingLabs.sha256_lookup(sha256_hash)
              rev_lab = FileReputationApi::ReversingLabs.lookup_immediate(params[:sha256_hash])

              begin
                score_attributes = FileReputationApi::ReversingLabs.score_of_lookup(api_response)
                FileReputationDispute.where(sha256_hash: sha256_hash).update_all(score_attributes)
              rescue => except
                Rails.logger.error("Error updating reversing labs score for sha256 hash #{sha256_hash} -- #{except.error_message}")
              end

              render json: rev_lab.api_response
            end
          end
        end
      end
    end
  end
end
