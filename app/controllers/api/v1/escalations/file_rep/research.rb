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
              std_api_v2 do
                if /\A\H*(?<sha256_hash>\h{64})\H*\z/ =~ permitted_params[:sha256_hash]
                  api_response = Threatgrid::Search.data(sha256_hash)
                  attributes = Threatgrid::Search.query_from_data(api_response)
                  FileReputationDispute.where(sha256_hash: sha256_hash).update_all(attributes)
                  render json: api_response
                else
                  exception = RuntimeError.new('Not a valid SHA256')
                  exception.set_backtrace(caller)
                  std_exception(exception, status: :bad_request)
                end
              end
            end
          end
        end
      end
    end
  end
end
