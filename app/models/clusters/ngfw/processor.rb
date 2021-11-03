class Clusters::Ngfw::Processor < Clusters::Templates::Processor
  attr_reader :cluster, :user

  def initialize(cluster, user)
    @cluster = cluster
    @user = user
  end

  def processable?
    ngfw_cluster.created? # pending and processed clusters are not processable
  end

  def process_2nd_person_review
    ngfw_cluster.update_attributes(category_ids: cluster[:categories].map(&:to_i).to_json) # mysql can't store arrays =(
    ngfw_cluster.pending!
  end

  def process
    unless ngfw_cluster.pending?
      # update cluster data from user input
      ngfw_cluster.update_attributes(category_ids: cluster[:categories].to_json, comment: cluster[:comment])
    end

    # process in the same way as complaint entries
    Wbrs::Prefix.create_from_url(
      url: ngfw_cluster.domain,
      categories: JSON.parse(ngfw_cluster.category_ids).map(&:to_i),
      user: user.email,
      description: ngfw_cluster.comment
    )
    ngfw_cluster.processed!
  end

  def decline
    ngfw_cluster.update_attributes(category_ids: '')
    # assign clusters to the person who declined current categorization
    ClusterAssignment.assign!(cluster, user)
    ngfw_cluster.created!
  end

  private

  def ngfw_cluster
    @ngfw_cluster ||= NgfwCluster.find_by(domain: cluster[:domain])
  end
end
