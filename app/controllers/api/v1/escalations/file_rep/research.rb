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
              api_response = Threatgrid::Search.data(permitted_params[:sha256_hash])
              render json: api_response
            end

            desc "update file rep columns"
            params do
              requires :id, type: Integer, desc: "file rep id"
            end
            post "update_file_rep_data" do

              filerep = FileReputationDispute.where(:id => permitted_params[:id]).first
              if filerep.present?
                filerep.update_trifecta
              end

              render json: {}

            end
          end
        end
      end
    end
  end
end
