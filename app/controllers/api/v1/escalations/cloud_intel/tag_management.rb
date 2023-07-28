module API
  module V1
    module Escalations
      module CloudIntel
        class TagManagement < Grape::API
          include API::V1::Defaults

          resource "escalations/cloud_intel/tag_management" do

            desc "Read tag information"
            params do
              optional :domain, type: String
              optional :ip, type: String
              optional :url, type: String
              optional :sha, type: String
            end
            get "read_observable" do
              std_api_v2 do
                authorize!(:read_observable, Tmi)
                ::CloudIntel::TagManagementInterface.read(domain: params[:domain],
                                                          ip: params[:ip],
                                                          url: params[:url],
                                                          sha: params[:sha])
              end
            end

            desc "Return the taxonomy map"
            get "taxonomy_map" do
              std_api_v2 do
                authorize!(:read_taxonomy_map, Tmi)
                map = ::EnrichmentService::TaxonomyMap.load_condensed_map
                JSON.parse(map)
              end
            end

            desc "Update an observable"
            params do
              group :items, type: Array do
                optional :domain, type: String
                optional :ip, type: String
                optional :url, type: String
                optional :sha, type: String
                optional :action, type: String
                group :tags, type: Array do
                  optional :tag_type_id, type: Integer, default: 1
                  optional :taxonomy_id, type: Integer
                  optional :taxonomy_entry_id, type: Integer
                end
              end
            end
            post "update_by_context" do
              std_api_v2 do
                authorize!(:update_observable, Tmi)
                response = ::Tmi::TmiGrpc.update_by_context(items: params[:items], source: current_user.cvs_username)
                response.to_h
              end
            end
          end
        end
      end
    end
  end
end