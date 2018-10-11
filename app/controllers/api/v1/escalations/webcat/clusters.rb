module API
  module V1
    module Escalations
      module Webcat
        class Clusters < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/clusters" do

            before do
              PaperTrail.whodunnit = current_user.id if current_user.present?
            end

            desc 'process cluster'
            params do
              requires :category_ids, type: Array, desc: 'List of category ids'
              requires :cluster_id, type: Integer, desc: 'ID of cluster to categorize'
              optional :comment, type: String, desc: 'comment to associate with rule'
            end

            post "process_cluster" do


              conditions = {}
              conditions[:cluster_id] = params[:cluster_id]
              conditions[:category_ids] = params[:category_ids]
              conditions[:comment] = params[:comment] unless params[:comment].blank?

              Wbrs::Cluster.process(conditions, true)
            end


            desc 'get all clusters'
            params do
            end

            get "" do
              authorize!(:index, Complaint)

              json_packet = []
              if params[:regex].present?
                clusters = Wbrs::Cluster.where({:regex => params[:regex]})
              else
                clusters = Wbrs::Cluster.all(true)
              end
              if clusters

                clusters.each do |cluster|
                  cluster_packet = {}

                  cluster_packet[:cluster_id] = cluster[:cluster_id]
                  cluster_packet[:domain] = cluster[:domain]
                  cluster_packet[:global_volume] = cluster[:glob_volume]

                  json_packet << cluster_packet
                end
              end
              {:status => "success", :data => json_packet}.to_json

            end

            #returns an array of hashes about urls associated with a cluster_id
            #{
            #    "apac_region_volume": 0,
            #    "emrg_region_volume": 0,
            #    "eurp_region_volume": 0,
            #    "glob_volume": 5,
            #    "japn_region_volume": 0,
            #    "na_region_volume": 0,
            #    "url": "http://www.facebook.com/plugins/like.php",
            #    "wbrs_score": 3.8
            #}
            desc ""
            params do

            end
            get ":id" do
              cluster_id = params[:id]

              cluster_info = Wbrs::Cluster.retrieve(cluster_id, true)
              {:status => "success", :data => cluster_info}.to_json
            end




          end
        end
      end
    end
  end
end
