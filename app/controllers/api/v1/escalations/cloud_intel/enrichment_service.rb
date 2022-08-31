module API
  module V1
    module Escalations
      module CloudIntel
        class EnrichmentService < Grape::API
          include API::V1::Defaults

          resource "escalations/cloud_intel/enrichment_service" do

            desc "Enrichment Service Context Data"
            params do
              requires :query_item, type: String
              optional :query_type, type: String
            end
            get "query" do
              std_api_v2 do
                query_type = params[:query_type]&.downcase
                case query_type
                when "domain"
                  results = ::EnrichmentService::QueryInterface.domain_query(params[:query_item])
                when "ip"
                  results = ::EnrichmentService::QueryInterface.ip_query(params[:query_item])
                when "url"
                  results = ::EnrichmentService::QueryInterface.url_query(params[:query_item])
                when "sha"
                  results = ::EnrichmentService::QueryInterface.sha_query(params[:query_item])
                else
                  results = ::EnrichmentService::QueryInterface.interpreted_query(params[:query_item])
                end
                { data: results }
              end
            end
          end
        end
      end
    end
  end
end