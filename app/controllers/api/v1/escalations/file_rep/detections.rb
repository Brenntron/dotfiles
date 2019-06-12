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
              optional :dispute_id, type: Integer
              requires :sha256_hashes, type: Array[String], desc: "SHA256 hashes"
              requires :disposition, type: String
              optional :detection_name, type: String
              optional :comment, type: String
              optional :old_disposition, type: String
            end
            post "" do
              std_api_v2 do
                result = FileReputationApi::Detection.create_action(sha256_hashes: params['sha256_hashes'],
                                                                    disposition: params['disposition'],
                                                                    detection_name: params['detection_name'])

                FileRepComment.create_action(params[:comment], params[:old_disposition], params[:disposition], params[:dispute_id], current_user)

                result.to_json
              end
            end
          end
        end
      end
    end
  end
end
