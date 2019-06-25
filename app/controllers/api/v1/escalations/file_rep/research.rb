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

                  begin
                    attributes = Threatgrid::Search.query_from_data(api_response)
                    FileReputationDispute.where(sha256_hash: sha256_hash).update_all(attributes)
                  rescue => except
                    Rails.logger.error("Error updating threatgrid score for sha256 hash #{sha256_hash} -- #{except.message}")
                  end

                  render json: api_response
                else
                  exception = RuntimeError.new('Not a valid SHA256')
                  exception.set_backtrace(caller)
                  std_exception(exception, status: :bad_request)
                end
              end
            end

            desc "update file rep columns"
            params do
              requires :id, type: Integer, desc: "file rep id"
            endgit
            post "update_file_rep_data" do

              filerep = FileReputationDispute.where(:id => permitted_params[:id]).first
              if filerep.present?
                filerep.update_superfecta
              end

              render json: {}

            end
          end
        end
      end
    end
  end
end
