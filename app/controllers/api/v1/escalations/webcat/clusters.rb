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
            rescue Exception => e
              {
                  status: 'failed',
                  error: e.message
              }.to_json
            end

            desc 'get all clusters'
            params do
              optional :f, type: String, desc: 'filter'
              optional :platform, type: String, desc: 'platform filter(WSA/NGFW/Umbrella)'
              optional :cluster_type, type: String, desc: 'cluster type filter(ip/domain)'
              
            end

            # Uses class Beaker::Verdicts in old Beaker namespace.
            get "" do
              authorize!(:index, Complaint)
              if params[:platform] == 'WSA'
                filter = {
                  f: params[:f],
                  platform: params[:platform],
                  cluster_type: params[:cluster_type]
                }
                clusters = ::Clusters::Fetcher.new(filter, params[:regex], params[:save_regex], current_user).fetch
                response = {:status => "success", :data => clusters}
              else
                response = ::Clusters::Datatable.new(ActionController::Parameters.new(params).permit!, current_user)
              end
              response
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
              sorted_limited_cluster_info = cluster_info.sort { |x,y| y['glob_volume'] <=> x['glob_volume'] }.first(300)

              { status: 'success', data: sorted_limited_cluster_info }.to_json
            end

            post 'multiple' do
              clusters_info = Wbrs::Cluster.retrieve_many(params[:ids])['data']
              sorted_limited_cluster_info =  clusters_info.reduce({}) do |result, (id, clusters)|
                result[id] = clusters.sort { |x, y| y['glob_volume'] <=> x['glob_volume'] }.first(300)
                result
              end
              puts sorted_limited_cluster_info
              { status: 'success', data: sorted_limited_cluster_info }.to_json
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

            desc 'unassign cluster from the user'
            params do
            end
            post 'return' do
              clusters = JSON.parse(params[:clusters], symbolize_names: true)
              ::Clusters::Assignor.new(clusters, current_user).unassign
              return { status: 'success' }.to_json
            rescue Exception => e
              {
                status: 'failed',
                error: e.message
              }.to_json
            end

            desc 'process important clusters'
            params do
            end
            post 'proccess' do
              clusters = [params[:cluster]]
              # js converts array to hash on sending for some reason => .values
              clusters += params.dig(:cluster, :duplicates).values if params.dig(:cluster, :duplicates).present?
              ::Clusters::Processor.new(clusters, current_user).process!
              return { status: 'success' }.to_json
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
              return { status: 'success' }.to_json
              rescue Exception => e
              {
                  status: 'failed',
                  error: e.message
              }.to_json
            end

            desc 'decline important clusters categorization'
            params do
            end
            post 'decline' do
              clusters = [params[:cluster]]
              # js converts array to hash on sending for some reason => .values
              clusters += params.dig(:cluster, :duplicates).values if params.dig(:cluster, :duplicates).present?
              ::Clusters::Processor.new(clusters, current_user).decline
              return { status: 'success' }.to_json
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

            desc "Delete saved regex searches for webcat clusters"
            params do
              requires :search_name, type: String, desc: 'filter'
            end
            delete "searches" do
              # TODO determine access control policy for named searches
              search = NamedSearch.where(name: params['search_name'], user: current_user, project_type: 'webcat_clusters_regex')
              search.destroy_all
              true
            end

            desc 'save regex search for webcat clusters'
            params do
              requires :regex, type: String, desc: 'filter'
              requires :save_regex
            end

            post 'searches' do
              named_search = current_user.named_searches.where(name: params[:regex]).first

              if params[:save_regex].present? && params[:regex].present? && named_search.nil?
                named_search = NamedSearch.create!(user: current_user, name: params[:regex], project_type: 'webcat_clusters_regex')
              end

              { status: 'success', data: named_search }.to_json

            end

          end
        end
      end
    end
  end
end
