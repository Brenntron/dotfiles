class Clusters::Meraki::Processor < Clusters::Templates::Processor
  attr_reader :clusters, :user

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def process
    clusters.each do |cluster|
      credit_handler = WebcatCredits::Clusters::CreditHandler.new(user, cluster)
      next unless processable?(cluster)

      if cluster[:is_important]
        # skip processing, move cluster to 2nd person review
        process_2nd_person_review(cluster)
        # add pending credit to the user
        credit_handler.handle_pending_credit
      else
        process_cluster!(cluster)
        # add fixed credit to the user, regardless of platform
        credit_handler.handle_fixed_credit
      end
    end
  end

  def process!
    raise_manager_exception = false
    manager_count = []
    clusters.each do |cluster|
      next if cluster[:is_pending].present? && cluster[:is_pending] == false

      if third_person_review_cluster?(cluster)
        # prevent bulk processing for 3rd person review clusters
        manager_user = User.where(cvs_username: Complaint::MAIN_WEBCAT_MANAGER_CONTACT).first
        ClusterAssignment.assign_permanent!(cluster, manager_user)
        raise_manager_exception = true
        manager_count << cluster[:domain]
      else
        process_cluster!(cluster)
        # add fixed credit to the user
        WebcatCredits::Clusters::CreditHandler.new(user, cluster).handle_fixed_credit
      end
    end

    if raise_manager_exception == true
      raise "Manager needs to approve clusters: [#{manager_count.join(",")}]"
    end
  end

  def decline
    cluster_domains = clusters.map { |cluster| cluster[:domain] }
    WebCatCluster.meraki.where(domain: cluster_domains).update(category_ids: '', status: :created)
    # assign clusters to the person who declined current categorization
    clusters.each do |cluster|
      ClusterAssignment.assign!(cluster, user)
    end
  end

  private

  def credit_handler
    @credit_handler ||= WebcatCredits::Clusters::CreditHandler.new(user, cluster)
  end

  def processable?(cluster)
    db_cluster = meraki_cluster(cluster)
    db_cluster.created? # pending and processed clusters are not processable
  end

  def process_2nd_person_review(cluster)
    db_cluster = meraki_cluster(cluster)
    db_cluster.update(category_ids: cluster[:categories].map(&:to_i).to_json) # mysql can't store arrays =(
    db_cluster.pending!
  end

  def process_cluster!(cluster)
    db_cluster = meraki_cluster(cluster)
    unless db_cluster.pending?
      # update cluster data from user input
      db_cluster.update(category_ids: cluster[:categories].to_json, comment: cluster[:comment])
    end

    # process in the same way as complaint entries
    Wbrs::Prefix.create_from_url(
        url: db_cluster.domain,
        categories: JSON.parse(db_cluster.category_ids).map(&:to_i),
        user: user.email,
        description: db_cluster.comment
    )
    db_cluster.processed!
  end

  def meraki_cluster(cluster)
    WebCatCluster.meraki.find_by(domain: cluster[:domain])
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
