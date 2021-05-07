class Clusters::Assignor
  attr_reader :clusters, :user

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def assign
    clusters.each do |cluster|
      ClusterAssignment.assign(cluster[:domain], user)
    end
  end

  def unassign
    clusters.each do |cluster|
      ClusterAssignment.unassign(cluster[:domain], user)
    end
  end
end
