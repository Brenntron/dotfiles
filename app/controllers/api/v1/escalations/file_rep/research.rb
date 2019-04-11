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

              submitted_to_tg = api_response
              run_status = api_response
              threat_score = api_response&.dig('data','items')[0]&.dig('item','analysis','threat_score')

              # Tags (can contain many entries)
              tag_data = api_response
              tags = api_response

              control = api_response
              vm_name = api_response
              run_time = api_response
              os = api_response

              # Behaviors (can contain many entries)
              behavior_data = api_response
              behaviors = api_response

              full_json = api_response

              render json: {full_json: api_response}
            end
          end
        end
      end
    end
  end
end
