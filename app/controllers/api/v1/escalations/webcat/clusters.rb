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
              optional :f, type: String, desc: 'filter'
            end

            get do
              authorize!(:index, Complaint)
              clusters = ::Webcat::ClustersFetcher.new(params[:f], params[:regex], current_user).fetch

              {:status => "success", :data => clusters[:data], :meta => clusters[:meta]}.to_json
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

            desc "assign cluster to the user"
            params do
            end
            post 'take' do
              cluster_ids = params[:cluster_ids]
              ClusterAssignment.assign(cluster_ids, current_user)
              {
                status: "success",
                username: current_user.cvs_username,
                cluster_ids: cluster_ids
              }.to_json

            rescue Exception => e
              {
                status: 'failed',
                error: e.message
              }.to_json
            end

            desc "unassign cluster from the user"
            params do
            end
            post 'return' do
              cluster_ids = params[:cluster_ids]
              ClusterAssignment.unassign(cluster_ids, current_user)
              return {:status => "success"}.to_json
            rescue Exception => e
              {
                status: 'failed',
                error: e.message
              }.to_json
            end
          end
        end
      end
    end
  end
end
