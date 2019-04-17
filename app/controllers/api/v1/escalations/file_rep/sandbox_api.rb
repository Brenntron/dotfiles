module API
  module V1
    module Escalations
      module FileRep
        class SandboxApi < Grape::API
          resource "escalations/filerep/sandbox_api" do

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_score/:sha256_hash" do
              api_response = FileReputationApi::SandboxApi.sandbox_score(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_disposition/:sha256_hash" do
              api_response = FileReputationApi::SandboxApi.sandbox_disposition(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
            end
            get "/sandbox_latest_report/:sha256_hash" do
              api_response = FileReputationApi::SandboxApi.sandbox_latest_report(params[:sha256_hash])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
              requires :run_id, type: Integer, desc: "Run ID for a given sha256"
            end
            get "/sandbox_report/:run_id/:sha256_hash" do
              api_response = FileReputationApi::SandboxApi.full_report(params[:sha256_hash], params[:run_id])
              render json: api_response
            end

            desc ''
            params do
              requires :sha256_hash, type: String, desc: "SHA256 hash"
              requires :run_id, type: Integer, desc: "Run ID for a given sha256"
            end
            get "/sandbox_report_html/:run_id/:sha256_hash" do
              api_response = FileReputationApi::SandboxApi.full_report_html(params[:sha256_hash], params[:run_id])
              render json: api_response
            end
          end
        end
      end
    end
  end
end
