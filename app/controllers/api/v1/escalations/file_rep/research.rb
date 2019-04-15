module API
  module V1
    module Escalations
      module FileRep
        class Research < Grape::API
          resource "escalations/file_rep/disputes/" do

            desc 'Make an API call to ThreatGrid to populate Research data'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end

            # get 'refresh_visible_research_tab'
            #   data = FileReputationDispute.refresh_visible_research_tab()
            #
            #   response_data = {:status => "success", :data => data}
            #
            #   response_data.to_json
            #
            # end
            post "" do
              api_response = Threatgrid::Search.data(permitted_params[:sha256_hash])
              render json: api_response
            end
          end
        end
      end
    end
  end
end
