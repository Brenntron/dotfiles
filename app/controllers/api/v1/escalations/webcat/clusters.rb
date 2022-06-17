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
              requires :clusters, type: String, desc: 'stringified json with clusters data'
            end

            post "process_cluster" do
              cluster_process_array = []

              clusters = JSON.parse(params[:clusters], symbolize_names: true)
              ::Clusters::Assignor.new(clusters, current_user).assign_permanent!
              ::Clusters::Processor.new(clusters, current_user).process
              return {:status => "success"}.to_json
            end

            desc 'get all clusters'
            params do
              optional :f, type: String, desc: 'filter'
              optional :platform, type: String, desc: 'platform filter(WSA/NGFW)'
              optional :cluster_type, type: String, desc: 'cluster type filter(ip/domain)'
            end

            # Uses class Beaker::Verdicts in old Beaker namespace.
            get "" do
              authorize!(:index, Complaint)

              filter = {
                f: params[:f],
                platform: params[:platform],
                cluster_type: params[:cluster_type]
              }
              clusters = ::Clusters::Fetcher.new(filter, params[:regex], current_user).fetch

              {:status => "success", :data => clusters}.to_json
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
              clusters = JSON.parse(params[:clusters], symbolize_names: true)
              ::Clusters::Assignor.new(clusters, current_user).assign
              {
                status: "success",
                username: current_user.cvs_username,
                clusters: clusters
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
              clusters = JSON.parse(params[:clusters], symbolize_names: true)
              ::Clusters::Assignor.new(clusters, current_user).unassign
              return {:status => "success"}.to_json
            rescue Exception => e
              {
                status: 'failed',
                error: e.message
              }.to_json
            end

            desc "process important clusters"
            params do
            end
            post 'proccess' do
              cluster = params[:cluster]
              ::Clusters::Processor.new([cluster], current_user).process!
              return {:status => "success"}.to_json
            rescue Exception => e
              {
                status: 'failed',
                error: e.message
              }.to_json
            end

            desc "process multiple reviewed important clusters"
            params do
            end
            post 'process_multiple_reviewed' do
              clusters = JSON.parse(params[:clusters], symbolize_names: true)
              ::Clusters::Processor.new(clusters, current_user).process!
              return {:status => "success"}.to_json
              rescue Exception => e
              {
                  status: 'failed',
                  error: e.message
              }.to_json
            end



            desc "decline important clusters categorization"
            params do
            end
            post 'decline' do
              cluster = params[:cluster]
              ::Clusters::Processor.new([cluster], current_user).decline
              return {:status => "success"}.to_json
            rescue Exception => e
              {
                status: 'failed',
                error: e.message
              }.to_json
            end


            desc "decline important clusters categorization"
            params do
            end
            post 'decline_multiple_reviewed' do
              clusters = JSON.parse(params[:clusters], symbolize_names: true)
              ::Clusters::Processor.new(clusters, current_user).decline
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
