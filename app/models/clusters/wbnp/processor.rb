class Clusters::Wbnp::Processor < Clusters::Templates::Processor
  attr_reader :cluster, :user

  def initialize(cluster, user)
    @cluster = cluster
    @user = user
  end

  def processable?
    ClusterCategorization.where(cluster_id: cluster[:cluster_id]).empty?
  end

  def process_2nd_person_review
    ClusterCategorization.create(
      user_id: user.id,
      cluster_id: cluster[:cluster_id],
      comment: cluster[:comment],
      category_ids: cluster[:categories].map(&:to_i).to_json # mysql can't store arrays =(
    )
  end

  def process
    Wbrs::Cluster.process(
      comment: cluster[:comment],
      user: user.cvs_username,
      cluster_id: cluster[:cluster_id],
      cat_ids: cluster[:categories].map(&:to_i)
    )
    ClusterCategorization.where(cluster_id: cluster[:cluster_id]).destroy_all
  end

  def decline
    ClusterCategorization.where(cluster_id: cluster[:cluster_id]).destroy_all
    # assign clusters to the person who declined current categorization
    ClusterAssignment.assign!(cluster[:domain], user)
  end
end
