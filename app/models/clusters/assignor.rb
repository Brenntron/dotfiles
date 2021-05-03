class Clusters::Assignor
  attr_reader :clusters, :user

  PLATROFM_PROVIDERS = {
    'WSA' => Clusters::Wbnp::Assignor
  }

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def assign
    clusters.each do |cluster|
      PLATROFM_PROVIDERS[cluster[:platform]].new(cluster, user).assign
    end
  end

  def unassign
    clusters.each do |cluster|
      PLATROFM_PROVIDERS[cluster[:platform]].new(cluster, user).unassign
    end
  end
end
