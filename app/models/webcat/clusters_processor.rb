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

    def process!(cluster_ids, current_user)
      ClusterCategorization.where(cluster_id: cluster_ids).each do |cluster_categorization|
        if third_person_review_cluster?(cluster_categorization, current_user)
          manager_user = User.where(cvs_username: Complaint::MAIN_WEBCAT_MANAGER_CONTACT).first
          ClusterAssignment.assign_permanent!(cluster_ids, manager_user)

          raise 'Cluster should pass manager review'
        else
          proccess_on_wbrs(
            comment: cluster_categorization.comment,
            user: cluster_categorization.user.cvs_username,
            cluster_id: cluster_categorization.cluster_id,
            cat_ids: JSON.parse(cluster_categorization.category_ids) # mysql can't store arrays =(
          )
          cluster_categorization.destroy
        end
      end
    end

    def decline!(cluster_ids, current_user)
      ClusterCategorization.where(cluster_id: cluster_ids).destroy_all
      # assign clusters to the person who declined current categorization
      ClusterAssignment.assign!(cluster_ids, current_user)
    end

    private

    def third_person_review_cluster?(cluster_categorization, current_user)
      # third person review - should be done by webcat manager
      return false if current_user.is_webcat_manager? # webcat managers skip 3rd person review

      cluster_url = Wbrs::Cluster.retrieve(cluster_categorization.cluster_id).first['url']
      prefix = URI.parse(cluster_url).host
      categories = JSON.parse(cluster_categorization.category_ids)

      verdict_check = Webcat::EntryVerdictChecker.new(prefix, categories).check
      !verdict_check[:verdict_pass]
    end

    def proccess_on_wbrs(data)
      Wbrs::Cluster.process(data)
    end
  end
end
