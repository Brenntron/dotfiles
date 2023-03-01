class Clusters::Assignor
  attr_reader :clusters, :user

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def assign
    clusters.each do |cluster|
      ClusterAssignment.assign(cluster, user)
    end
  end

  def assign!
    clusters.each do |cluster|
      ClusterAssignment.assign!(cluster, user)
    end
  end

  def assign_permanent!
    clusters.each do |cluster|
      ClusterAssignment.assign_permanent!(cluster, user)
    end
  end

  def unassign
    clusters.each do |cluster|
      ClusterAssignment.unassign(cluster, user)
    end
  end
end
