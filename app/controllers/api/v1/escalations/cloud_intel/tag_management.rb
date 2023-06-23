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
                results = ::Tmi::TmiGrpc.read(domain: params[:domain],
                                              ip: params[:ip],
                                              url: params[:url],
                                              sha: params[:sha])

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

            desc "Add a tag"
            params do
              optional :domain, type: String
              optional :ip, type: String
              optional :url, type: String
              optional :sha, type: String
              requires :taxonomy_id, type: Integer
              requires :taxonomy_entry_id, type: Integer
            end
            post "add_tag" do
              std_api_v2 do
                item = {
                    domain: params[:domain],
                    ip: params[:ip],
                    url: params[:url],
                    sha: params[:sha],
                    action: "add",
                    tags: [{
                               tag_type_id: 1,
                               taxonomy_id: params[:taxonomy_id],
                               taxonomy_entry_id: params[:taxonomy_entry_id]
                           }]
                }
                Tmi::TmiGrpc.update_by_context(items: [item])
              end
            end

            desc "Remove a tag"
            params do
              optional :domain, type: String
              optional :ip, type: String
              optional :url, type: String
              optional :sha, type: String
              requires :taxonomy_id, type: Integer
              requires :taxonomy_entry_id, type: Integer
            end
            post "remove_tag" do
              std_api_v2 do
                item = {
                    domain: params[:domain],
                    ip: params[:ip],
                    url: params[:url],
                    sha: params[:sha],
                    action: "delete",
                    tags: [{
                               tag_type_id: 1,
                               taxonomy_id: params[:taxonomy_id],
                               taxonomy_entry_id: params[:taxonomy_entry_id]
                           }]
                }
                Tmi::TmiGrpc.update_by_context(items: [item])
              end
            end

            desc "Suppress a tag"
            params do
              optional :domain, type: String
              optional :ip, type: String
              optional :url, type: String
              optional :sha, type: String
              requires :taxonomy_id, type: Integer
              requires :taxonomy_entry_id, type: Integer
            end
            post "suppress_tag" do
              std_api_v2 do
                item = {
                    domain: params[:domain],
                    ip: params[:ip],
                    url: params[:url],
                    sha: params[:sha],
                    action: "suppress",
                    tags: [{
                               tag_type_id: 1,
                               taxonomy_id: params[:taxonomy_id],
                               taxonomy_entry_id: params[:taxonomy_entry_id]
                           }]
                }
                Tmi::TmiGrpc.update_by_context(items: [item])
              end
            end

            desc "Unsuppress a tag"
            params do
              optional :domain, type: String
              optional :ip, type: String
              optional :url, type: String
              optional :sha, type: String
              requires :taxonomy_id, type: Integer
              requires :taxonomy_entry_id, type: Integer
            end
            post "unsuppress_tag" do
              std_api_v2 do
                item = {
                    domain: params[:domain],
                    ip: params[:ip],
                    url: params[:url],
                    sha: params[:sha],
                    action: "unsuppress",
                    tags: [{
                               tag_type_id: 1,
                               taxonomy_id: params[:taxonomy_id],
                               taxonomy_entry_id: params[:taxonomy_entry_id]
                           }]
                }
                Tmi::TmiGrpc.update_by_context(items: [item])
              end
            end
          end
        end
      end
    end
  end
end