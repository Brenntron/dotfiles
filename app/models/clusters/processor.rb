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
    clusters.each do |cluster|
      cluster_processor = PLATFORM_PROVIDERS[cluster[:platform]].new(cluster, user)
      next unless cluster_processor.processable?

      if cluster[:is_important]
        # skip processing, move cluster to 2nd person review
        cluster_processor.process_2nd_person_review
        # TODO: add credit to the user
      else
        cluster_processor.process
        # TODO: add credit to the user
      end
    end
  end

  def process!
    clusters.each do |cluster|
      if third_person_review_cluster?(cluster)
        manager_user = User.where(cvs_username: Complaint::MAIN_WEBCAT_MANAGER_CONTACT).first
        ClusterAssignment.assign_pemanent!(cluster[:domain], manager_user)

        raise 'Cluster should pass manager review'
      else
        PLATFORM_PROVIDERS[cluster[:platform]].new(cluster, user).process
        # TODO: add credit to the user
      end
    end
  end

  def decline
    clusters.each do |cluster|
      PLATFORM_PROVIDERS[cluster[:platform]].new(cluster, user).decline
      # TODO: add credit to the user
    end
  end

  private

  def third_person_review_cluster?
    # third person review - should be done by webcat manager
    return false if user.is_webcat_manager? # webcat managers skip 3rd person review

    prefix = cluster[:domain]
    categories = JSON.parse(cluster[:categories].map(&:to_i))

    verdict_check = Webcat::EntryVerdictChecker.new(prefix, categories).check
    !verdict_check[:verdict_pass]
  end
end
