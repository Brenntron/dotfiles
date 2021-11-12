class Clusters::Processor
  attr_reader :clusters, :user

  PLATFORM_PROVIDERS = {
    'WSA' => Clusters::Wbnp::Processor,
    'NGFW' => Clusters::Ngfw::Processor
  }

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def process
    bulk_wbnp_clusters = []
    # First, handle non-WSA clusters. WSA is handled in bulk later, so they don't get http requests
    # in this loop.
    clusters.each do |cluster|
      credit_handler = WebcatCredits::Clusters::CreditHandler.new(user, cluster)
      cluster_processor = PLATFORM_PROVIDERS[cluster[:platform]].new(cluster, user)
      next unless cluster_processor.processable?

      if cluster[:is_important]
        # skip processing, move cluster to 2nd person review
        cluster_processor.process_2nd_person_review
        # add pending credit to the user
        credit_handler.handle_pending_credit
      else
        if cluster[:platform] == 'WSA'
          wbnp_cluster = {
            cluster_id: cluster[:cluster_id],
            cat_ids: cluster[:categories].map(&:to_i),
            user: user.cvs_username,
            comment: cluster[:comment]
          }
          bulk_wbnp_clusters << wbnp_cluster
        else
          cluster_processor.process
        end
        # add fixed credit to the user, regardless of platform
        credit_handler.handle_fixed_credit
      end
    end

    Wbrs::Cluster.process(bulk_wbnp_clusters)

  end

  def process!
    raise_manager_exception = false
    manager_count = []
    clusters.each do |cluster|
      next if cluster[:is_pending].present? && cluster[:is_pending] == false
      if third_person_review_cluster?(cluster)
        manager_user = User.where(cvs_username: Complaint::MAIN_WEBCAT_MANAGER_CONTACT).first
        ClusterAssignment.assign_pemanent!(cluster, manager_user)
        raise_manager_exception = true
        manager_count << cluster[:domain]
      else
        PLATFORM_PROVIDERS[cluster[:platform]].new(cluster, user).process
        # add fixed credit to the user
        credit_handler = WebcatCredits::Clusters::CreditHandler.new(user, cluster)
        credit_handler.handle_fixed_credit
      end
    end

    if raise_manager_exception == true
      raise "Manager needs to approve cluster ids: [#{manager_count.join(",")}]"
    end
  end

  def decline
    clusters.each do |cluster|
      PLATFORM_PROVIDERS[cluster[:platform]].new(cluster, user).decline
      # add unchanged credit to the user
      credit_handler = WebcatCredits::Clusters::CreditHandler.new(user, cluster)
      credit_handler.handle_unchanged_credit
    end
  end

  private

  def third_person_review_cluster?(cluster)
    # third person review - should be done by webcat manager
    return false if user.is_webcat_manager? # webcat managers skip 3rd person review

    prefix = cluster[:domain]
    categories = cluster[:categories].map(&:to_i)

    verdict_check = Webcat::EntryVerdictChecker.new(prefix, categories).check
    !verdict_check[:verdict_pass]
  end
end
