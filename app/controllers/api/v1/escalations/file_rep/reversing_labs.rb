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
              rev_lab = FileReputationApi::ReversingLabs.lookup_immediate(sha256_hash)

              begin
                rev_lab.update_database
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
