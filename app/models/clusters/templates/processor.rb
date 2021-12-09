class Clusters::Templates::Processor
  # This is template class for cluster provider assignor.
  # this class defines an interface, that should be implemented
  # by cluster data provider to support clusters processing
  # all methods here don't have implementation and acts following the Template Method pattern

  def process
    # processes cluster with checking if the cluster needs 2nd person review
    # cluster processing means sending cluster categorization data(category ids, etc) to specific server
    raise "#{self.class} should implement .process method"
  end

  def process!
    # processes cluster without 2nd person review check
    # cluster processing means sending cluster categorization data(category ids, etc) to specific server
    raise "#{self.class} should implement .process method"
  end

  def decline
    # declines clusters categorizaion
    # cluster have the categorizaion when it is on 2nd person review
    raise "#{self.class} should implement .process method"
  end

  private

  def processable?(cluster)
    # checks if the cluster can be processed
    # or the processing should be postponed(e.g. for 2nd or 3rd person review)
    raise "#{self.class} should implement .processable? method"
  end

  def process_2nd_person_review(cluster)
    # processes cluster to the 2nd person review
    # 2nd person review is an additional cluster review by any user before the cluster processing
    raise "#{self.class} should implement .process_2nd_person_review method"
  end

  def third_person_review_cluster?(cluster)
    # checks if the cluster is under 3rd person(manager) review
    # 3nd person review is an additional cluster review by manager before the cluster processing
    raise "#{self.class} should implement .third_person_review_cluster? method"
  end
end
