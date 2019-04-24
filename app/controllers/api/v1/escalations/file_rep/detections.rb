module API
  module V1
    module Escalations
      module FileRep
        class Detections < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession
          resource "escalations/file_rep/detections" do

            desc 'Create detection'
            params do
              optional :file_reputation_dispute_ids, type: Array[Integer]
              requires :sha256_hashes, type: Array[String], desc: "SHA256 hashes"
              requires :disposition, type: String
              optional :detection_name, type: String
            end
            post "" do
              std_api_v2 do
                FileReputationApi::Detection.create_action(sha256_hashes: params['sha256_hashes'],
                                                           disposition: params['disposition'],
                                                           detection_name: params['detection_name'],
                                                           ids: params['file_reputation_dispute_ids'])
              end
            end
          end
        end
      end
    end
  end
end
