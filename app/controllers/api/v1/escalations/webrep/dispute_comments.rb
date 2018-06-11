module API
  module V1
    module Escalations
      module Webrep
        class DisputeComments < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/dispute_comments" do

            desc "get a dispute comment"
            params do
              requires :id, type: String, desc: "ID of the dispute comment"
            end

            get ":id", root: "dispute_comment" do
              DisputeComment.where(id: permitted_params[:id])
            end

            desc "edit a dispute comment"
            params do
              requires :id, type: Integer, desc: "The dispute comment's id in the database."
              requires :current_user_id, type: Integer, desc: "The id of the user authoring the comment."
              requires :comment, type: String, desc: "The contents of the comment."
            end

            put ":id", root: "dispute_comment" do
              @dispute_comment = DisputeComment.find(permitted_params[:id])
              if @dispute_comment.user.id == permitted_params[:current_user_id]
                @dispute_comment.update_attributes(comment: permitted_params[:comment])
              else
                raise 'Unable to edit a note written by another user.'
              end
            end

            desc "create a dispute comment"
            params do
              requires :dispute_id, type: Integer, desc: "The id of the dispute the comment should be linked to."
              requires :user_id, type: Integer, desc: "The id of the user authoring the comment."
              requires :comment, type: String, desc: "The body of the note."
            end

            post "", root: "dispute_comment" do
              DisputeComment.create(permitted_params)
            end

            desc "delete a dispute comment"
            params do
              requires :id, type: Integer, desc: "The dispute comment's id in the database."
              requires :current_user_id, type: Integer, desc: "The id of the current user."
            end

            delete ":id", root: "dispute_comment" do
              @dispute_comment = DisputeComment.find(permitted_params[:id])
              if @dispute_comment.user.id == permitted_params[:current_user_id]
                @dispute_comment.destroy
              else
                raise 'Unable to delete a note written by another user.'
              end
            end
          end
        end
      end
    end
  end
end