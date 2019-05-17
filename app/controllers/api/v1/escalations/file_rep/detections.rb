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
              requires :sha256_hashes, type: Array[String], desc: "SHA256 hashes"
              requires :disposition, type: String
              optional :detection_name, type: String
            end
            post "" do
              std_api_v2 do
                result = FileReputationApi::Detection.create_action(sha256_hashes: params['sha256_hashes'],
                                                                    disposition: params['disposition'],
                                                                    detection_name: params['detection_name'])
                result.to_json
              end
            end

            desc 'Get updated detection data'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get ":sha256_hash/now" do
              std_api_v2 do
                detection = FileReputationApi::Detection.get_bulk(params['sha256_hash'])

                begin
                  FileReputationDispute.where(sha256_hash: detection.sha256_hash)
                      .update_all(disposition: detection.disposition,
                                  detection_name: detection.name)
                rescue
                  Rails.logger.error("Error saving updated detection information -- #{$!.message}")
                end

                { detection_name: detection.name, disposition: detection.disposition }
              end
            end
          end
        end
      end
    end
  end
end
