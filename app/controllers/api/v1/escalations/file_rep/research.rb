module API
  module V1
    module Escalations
      module FileRep
        class Research < Grape::API
          resource "escalations/filerep/research" do

            desc 'Make an API call to ThreatGrid to populate Research data'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            post "" do
              sha256_hash = permitted_params[:sha256_hash]
              api_response = Threatgrid::Search.data(sha256_hash)
              attributes = Threatgrid::Search.query_from_data(api_response)
              FileReputationDispute.where(sha256_hash: sha256_hash).update_all(attributes)
              render json: api_response
            end
          end
        end
      end
    end
  end
end
