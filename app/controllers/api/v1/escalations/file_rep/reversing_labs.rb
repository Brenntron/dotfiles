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
              api_response = FileReputationApi::ReversingLabs.sha256_lookup(params[:sha256_hash])
              render json: api_response
            end
          end
        end
      end
    end
  end
end
