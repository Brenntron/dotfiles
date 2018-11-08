module API
  module V1
    module Escalations
      module Webcat
        class Clusters < Grape::API
          include API::V1::Defaults
          include ActionView::Helpers::DateHelper
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
                clusters = Wbrs::Cluster.all()
              end
              if clusters

                clusters.each do |cluster|
                  cluster_packet = {}
                  cluster_packet[:cluster_id] = cluster["cluster_id"]
                  cluster_packet[:domain] = cluster["domain"]
                  cluster_packet[:global_volume] = cluster["glob_volume"]
                  cluster_packet[:ctime] = cluster["ctime"]
                  #cluster_packet[:now] = Time.now.utc.to_i
                  cluster_packet[:age] = distance_of_time_in_words(Time.now, Time.parse(cluster["ctime"]))
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

              cluster_info = Wbrs::Cluster.retrieve(cluster_id)
              {:status => "success", :data => cluster_info}.to_json
            end

            params do
              requires :category_ids, type: Array[Integer]
              optional :comment, type: String
              requires :user_id, type: Integer
              requires :id, type: Integer
            end

            post "process" do
              cluster_id = params[:id]
              user = User.find(:user_id)
              cat_ids = params[:category_ids]
              conds = {}
              conds[:cluster_id] = cluster_id
              if params[:comment].present?
                conds[:comment] = params[:comment]
              end
              conds[:user] = user.cvs_username
              conds[:cat_ids] = cat_ids
              #Wbrs::Cluster.process(conds)
            end
          end
        end
      end
    end
  end
end
