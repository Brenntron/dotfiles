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

            desc 'Get updated detection data'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get ":sha256_hash/now" do
              std_api_v2 do
                detection = FileReputationApi::Detection.get_bulk(params['sha256_hash'])
                detection_last_set = FileReputationApi::ElasticSearch.query(params['sha256_hash'])
                last_fetched = Time.now.utc

                begin
                  file_rep_dispute = FileReputationDispute.where(sha256_hash: detection.sha256_hash)
                  if detection_last_set == 'No history to display' && file_rep_dispute.detection_last_set
                    detection_last_set = file_rep_dispute.detection_last_set
                  end
                  file_rep_dispute.update_all(disposition: detection.disposition,
                                              detection_name: detection.name,
                                              detection_last_set: detection_last_set,
                                              last_fetched: last_fetched)
                rescue
                  Rails.logger.error("Error saving updated detection information -- #{$!.message}")
                end

                { detection_name: detection.name,
                  disposition: detection.disposition,
                  detection_last_set: detection_last_set,
                  last_fetched: last_fetched.strftime("%b %e, %Y %l:%M %p %Z")}
              end
            end

            desc 'Get history of detection data'
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get ":sha256_hash/history" do
              std_api_v2 do
                history = FileReputationApi::ElasticSearch.get_history(params['sha256_hash'])

                render json: history
              end
            end
          end
        end
      end
    end
  end
end
