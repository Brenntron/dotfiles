module API
  module V1
    module Escalations
      module FileRep
        class SampleZoo < Grape::API
          resource "escalations/file_rep/sample_zoo" do

            desc 'Make an API call to sample zoo in Elasticsearch to find out of this SHA256 is in the zoo'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get ":sha256_hash" do
              if /\A\H*(?<sha256_hash>\h{64})\H*\z/ =~ permitted_params[:sha256_hash]
                api_response = FileReputationApi::SampleZoo.sha256_lookup(sha256_hash)
                begin
                  attributes = FileReputationApi::SampleZoo.query_from_data(api_response)
                  FileReputationDispute.where(sha256_hash: sha256_hash).update_all(attributes)
                rescue => except
                  Rails.logger.error("Error looking to Samplezoo for sha256 hash #{sha256_hash} -- #{except.message}")
                end

                render json: attributes
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
