class Clusters::Wbnp::Assignor
  attr_reader :cluster, :user

  def initialize(cluster, user)
    @cluster = cluster
    @user = user
  end

  def assign
    ClusterAssignment.assign(cluster[:cluster_id], user)
  end

  def assign!
    ClusterAssignment.assign!(cluster[:cluster_id], user)
  end

  def unassign
    ClusterAssignment.unassign(cluster[:cluster_id], user)
  end
end
