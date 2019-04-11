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
              binding.pry
              Threatgrid::Search.data(permitted_params[:sha256_hash])
            end
          end
        end
      end
    end
  end
end
