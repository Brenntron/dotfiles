module API
  module V1
    module Escalations
      module CloudIntel
        class TagManagement < Grape::API
          include API::V1::Defaults

          resource "escalations/cloud_intel/tag_management" do

            desc "Read tag information"
            params do
              requires :query_item, type: String
              requires :query_type, type: String
            end
            get "read_observable" do
              std_api_v2 do
                query_type = params[:query_type]&.downcase
                case query_type
                when "domain"
                  results = ::Tmi::TmiGrpc.read(domain: params[:query_item])
                when "ip"
                  results = ::Tmi::TmiGrpc.read(ip: params[:query_item])
                when "url"
                  results = ::Tmi::TmiGrpc.read(url: params[:query_item])
                when "sha"
                  results = ::Tmi::TmiGrpc.read(sha: params[:query_item])
                else
                  raise Tmi::TmiError, "Invalid query type: #{query_type}"
                end
                { data: results.to_h }
              end
            end

            desc "Return the taxonomy map"
            get "taxonomy_map" do
              std_api_v2 do
                map = ::EnrichmentService::TaxonomyMap.load_condensed_map
                JSON.parse(map)
              end
            end
          end
        end
      end
    end
  end
end