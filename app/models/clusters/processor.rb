class Clusters::Processor
  attr_reader :clusters, :user

  PLATFORM_PROVIDERS = {
    'WSA' => Clusters::Wbnp::Processor,
    'NGFW' => Clusters::Ngfw::Processor,
    'Umbrella' => Clusters::Umbrella::Processor,
    'Meraki' => Clusters::Meraki::Processor
  }

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def process
    grouped_clusters = clusters.group_by{ |cluster| cluster[:platform] }
    grouped_clusters.each do |platform, clusters|
      PLATFORM_PROVIDERS[platform].new(clusters, user).process
    end
  end

  def process!
    grouped_clusters = clusters.group_by{ |cluster| cluster[:platform] }
    grouped_clusters.each do |platform, clusters|
      PLATFORM_PROVIDERS[platform].new(clusters, user).process!
    end
  end

  def decline
    grouped_clusters = clusters.group_by{ |cluster| cluster[:platform] }
    grouped_clusters.each do |platform, clusters|
      PLATFORM_PROVIDERS[platform].new(clusters, user).decline
    end
  end
end
