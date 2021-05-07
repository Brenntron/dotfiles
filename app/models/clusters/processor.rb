class Clusters::Processor
  attr_reader :clusters, :user

  PLATROFM_PROVIDERS = {
    'WSA' => Clusters::Wbnp::Processor,
    'NGFW' => Clusters::Ngfw::Processor
  }

  def initialize(clusters, user)
    @clusters = clusters
    @user = user
  end

  def process
    clusters.each do |cluster|
      cluster_processor = PLATROFM_PROVIDERS[cluster[:platform]].new(cluster, user)
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
      PLATROFM_PROVIDERS[cluster[:platform]].new(cluster, user).process
      # TODO: add credit to the user
    end
  end

  def decline
    clusters.each do |cluster|
      PLATROFM_PROVIDERS[cluster[:platform]].new(cluster, user).decline
      # TODO: add credit to the user
    end
  end
end
