module API
  module V1
    module Escalations
      module FileRep
        class Disputes < Grape::API
          desc "Create a FileReputation Dispute comment"
          params do
            requires :file_reputation_dispute_id, type: Integer, desc: "The id of the FileRep Dispute that the comment should be linked to."
            requires :user_id, type: Integer, desc: "The id of the user authoring the comment."
            requires :comment, type: String, desc: "The body of the note."
          end

          post "", root: "file_rep_dispute_comment" do
            std_api_v2 do
              authorize!(:create, DisputeComment)

              FileRepComment.create!(permitted_params)
              {:status => "success"}.to_json
            end
          end
        end
      end
    end
  end
end
