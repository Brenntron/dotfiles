class Clusters::Wbnp::Processor
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
    proccess_on_wbrs(
      comment: cluster[:comment],
      user: user.cvs_username,
      cluster_id: cluster[:cluster_id],
      cat_ids: cluster[:categories].map(&:to_i)
    )
  end

  def process!
    ClusterCategorization.where(cluster_id: cluster[:cluster_id]).each do |cluster_categorization|
      proccess_on_wbrs(
        comment: cluster_categorization.comment,
        user: cluster_categorization.user.cvs_username,
        cluster_id: cluster_categorization.cluster_id,
        cat_ids: JSON.parse(cluster_categorization.category_ids) # mysql can't store arrays =(
      )
      cluster_categorization.destroy
    end
  end

  def decline!
    ClusterCategorization.where(cluster_id: cluster[:cluster_id]).destroy_all
    # assign clusters to the person who declined current categorization
    Clusters::Wbnp::Assignor.new(cluster, user).assign!
  end

  private

  def proccess_on_wbrs(data)
    # binding.pry
    Wbrs::Cluster.process(data)
  end
end
