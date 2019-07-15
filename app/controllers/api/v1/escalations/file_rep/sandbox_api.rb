module API
  module V1
    module Escalations
      module FileRep
        class SandboxApi < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession

          resource "escalations/file_rep/sandbox_api" do
            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end
            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_score/:sha256_hash" do
              api_response =
                  FileReputationApi::Sandbox.sandbox_score(
                      params[:sha256_hash],
                      api_key_type: FileReputationDispute::SANDBOX_KEY_AC_REFRESH
                  )
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_disposition/:sha256_hash" do
              api_response = FileReputationApi::Sandbox.sandbox_disposition(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_latest_report/:sha256_hash" do
              api_response =
                  FileReputationApi::Sandbox.sandbox_latest_report(
                      params[:sha256_hash],
                      api_key_type: FileReputationDispute::SANDBOX_KEY_AC_REFRESH
                  )
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
              requires :run_id, type: Integer, desc: "Run ID for a given sha256"
            end
            get "/sandbox_report/:run_id/:sha256_hash" do
              sha256_hash = params[:sha256_hash]
              api_response =
                  FileReputationApi::Sandbox.full_report(
                      sha256_hash,
                      params[:run_id],
                      api_key_type: FileReputationDispute::SANDBOX_KEY_AC_REFRESH
                  )

              begin
                sandbox_score = api_response[:data]['score']
                FileReputationDispute.where(sha256_hash: sha256_hash).update_all(sandbox_score: sandbox_score)
              rescue => except
                Rails.logger.error("Error updating sandbox score for sha256 hash #{sha256_hash} -- #{except.error_message}")
              end

              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_run_sample/:sha256_hash" do
              api_response = FileReputationApi::Sandbox.run_sample(params[:sha256_hash])
              render json: api_response
            end
          end
        end
      end
    end
  end
end