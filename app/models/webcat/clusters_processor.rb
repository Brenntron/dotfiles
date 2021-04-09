class Webcat::ClustersProcessor
  class << self
    def process(clusters_data, current_user)
      clusters_data.each do |cluster|
        if cluster[:is_important]
          next if ClusterCategorization.where(cluster_id: cluster[:cluster_id]).any?

          # store data to db, skip proccessing
          ClusterCategorization.create(
            user_id: current_user.id,
            cluster_id: cluster[:cluster_id],
            comment: cluster[:comment],
            category_ids: cluster[:cat_ids].to_json # mysql can't store arrays =(
          )
        else
          proccess_on_wbrs(cluster.except(:domain, :is_important))
        end
      end
    end

    def process!(cluster_ids)
      ClusterCategorization.where(cluster_id: cluster_ids).each do |cluster_categorization|
        proccess_on_wbrs(
          comment: cluster_categorization.comment,
          user: cluster_categorization.user.cvs_username,
          cluster_id: cluster_categorization.cluster_id,
          cat_ids: JSON.parse(cluster_categorization.category_ids) # mysql can't store arrays =(
        )
        cluster_categorization.destroy
      end
    end

    def decline!(cluster_ids, current_user)
      ClusterCategorization.where(cluster_id: cluster_ids).destroy_all
      # assign clusters to the person who declined current categorization
      ClusterAssignment.assign!(cluster_ids, current_user)
    end

    private

    def proccess_on_wbrs(data)
      Wbrs::Cluster.process(data)
    end
  end
end
