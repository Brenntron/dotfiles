class Clusters::Wbnp::Processor < Clusters::Templates::Processor
  attr_reader :clusters, :user

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def process
    clusters_to_process = []
    clusters.each do |cluster|
      credit_handler = WebcatCredits::Clusters::CreditHandler.new(user, cluster)
      next unless processable?(cluster)

      if cluster[:is_important]
        # skip processing, move cluster to 2nd person review
        process_2nd_person_review(cluster)
        # add pending credit to the user
        credit_handler.handle_pending_credit
      else
        clusters_to_process.push(cluster) # clusters will be processed later with bulk processing
      end
    end
    process_clusters!(clusters_to_process)
  end

  def process!
    raise_manager_exception = false
    manager_count = []
    clusters_to_process = []
    clusters.each do |cluster|
      next if cluster[:is_pending].present? && cluster[:is_pending] == false

      if third_person_review_cluster?(cluster)
        # prevent bulk processing for 3rd person review clusters
        manager_user = User.where(cvs_username: Complaint::MAIN_WEBCAT_MANAGER_CONTACT).first
        ClusterAssignment.assign_permanent!(cluster, manager_user)
        raise_manager_exception = true
        manager_count << cluster[:domain]
      else
        clusters_to_process.push(cluster) # clusters will be processed later with bulk processing
      end
    end

    process_clusters!(clusters_to_process)

    if raise_manager_exception == true
      raise "Manager needs to approve clusters: [#{manager_count.join(",")}]"
    end
  end

  def decline
    cluster_ids = clusters.map { |cluster| cluster[:cluster_id] }
    ClusterCategorization.where(cluster_id: cluster_ids).destroy_all
    clusters.each do |cluster|
      # assign clusters to the person who declined current categorization
      ClusterAssignment.assign!(cluster, user)
    end
  end

  private

  def processable?(cluster)
    ClusterCategorization.where(cluster_id: cluster[:cluster_id]).empty?
  end

  def process_2nd_person_review(cluster)
    ClusterCategorization.create(
      user_id: user.id,
      cluster_id: cluster[:cluster_id],
      comment: cluster[:comment],
      category_ids: cluster[:categories].map(&:to_i).to_json # mysql can't store arrays =(
    )
  end

  def process_clusters!(clusters_to_process)
    clusters_to_process.each_slice(100) do |clusters_batch|
      Wbrs::Cluster.process(clusters_data_for(clusters_batch))
    end
    clusters_to_process.each do |cluster|
      # add credit for all clusters
      WebcatCredits::Clusters::CreditHandler.new(user, cluster).handle_fixed_credit
    end
    # remove categorizations for clusters
    cluster_ids = clusters_to_process.map { |cluster| cluster[:cluster_id] }
    ClusterCategorization.where(cluster_id: cluster_ids).destroy_all
  end

  def clusters_data_for(clusters)
    clusters.map do |cluster|
      {
        cluster_id: cluster[:cluster_id],
        cat_ids: cluster[:categories].map(&:to_i),
        user: user.cvs_username,
        comment: cluster[:comment]
      }
    end
  end

  def third_person_review_cluster?(cluster)
    # third person review - should be done by webcat manager
    return false if user.is_webcat_manager? # webcat managers skip 3rd person review

    prefix = cluster[:domain]
    categories = cluster[:categories].map(&:to_i)

    verdict_check = Webcat::EntryVerdictChecker.new(prefix, categories).check
    !verdict_check[:verdict_pass]
  end
end
