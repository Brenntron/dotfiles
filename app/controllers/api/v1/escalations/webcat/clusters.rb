module API
  module V1
    module Escalations
      module Webcat
        class Clusters < Grape::API
          include API::V1::Defaults
          include ActionView::Helpers::DateHelper
          resource "escalations/webcat/clusters" do

            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end

            desc 'process cluster'
            params do
              optional :comment, type: String, desc: 'comment to associate with rule'
              requires :user_id, type: Integer
            end

            post "process_cluster" do

              cluster_process_array = []


              params.keys.each do |key|
                if key.include?("cluster_id_")
                  conditions = {}

                  total_cats = params[key].to_a.size

                  conditions[:comment] = params[:comment] unless params[:comment].blank?
                  conditions[:user] = User.find(params[:user_id]).cvs_username
                  conditions[:cluster_id] = key.gsub("cluster_id_", "").to_i
                  conditions[:cat_ids] = Wbrs::Category.get_category_ids(params[key].to_a)

                  if conditions[:cat_ids].blank? || conditions[:cat_ids].size != total_cats || !conditions[:cat_ids].all? {|i| i.is_a?(Integer)}
                    raise "could not resolve categories (#{params[key].to_a}) for cluster id #{conditions[:cluster_id]}, stopping process."
                  end
                  cluster_process_array << conditions
                end
              end

              if cluster_process_array.blank?
                raise "no categories were selected for any cluster, nothing happened."
              end

              cluster_process_array.each do |conds|
                Wbrs::Cluster.process(conds)
              end
              return {:status => "success"}.to_json

            end


            desc 'get all clusters'
            params do
            end

            get "" do
              authorize!(:index, Complaint)

              json_packet = []


              if params[:regex].present?
                cluster_data = Wbrs::Cluster.where({:regex => params[:regex]})
                clusters = cluster_data["data"]
                meta = cluster_data["meta"]
              else
                cluster_data = Wbrs::Cluster.all()
                clusters = cluster_data["data"]
                meta = cluster_data["meta"]
              end

              if clusters
                clusters.each do |cluster|
                  cluster_packet = {}
                  cluster_packet[:cluster_id] = cluster["cluster_id"]
                  cluster_packet[:domain] = cluster["domain"]
                  cluster_packet[:global_volume] = cluster["glob_volume"]
                  cluster_packet[:ctime] = cluster["ctime"]
                  cluster_packet[:cluster_size] = cluster["cluster_size"] unless cluster["cluster_size"].blank?
                  cluster_packet[:age] = distance_of_time_in_words(Time.now, Time.parse(cluster["ctime"]))
                  json_packet << cluster_packet
                end
              end
              {:status => "success", :data => json_packet, :meta => meta}.to_json

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

              sorted_limited_cluster_info = cluster_info.sort { |x,y| y["glob_volume"] <=> x["glob_volume"] }.first(300)

              {:status => "success", :data => sorted_limited_cluster_info}.to_json
            end
          end
        end
      end
    end
  end
end
