class Clusters::Templates::DataFetcher
  # This is template class for cluster provider assignor.
  # this class defines an interface, that should be implemented
  # by cluster data provider to support data fetching from origin source
  # all methods here don't have implementation and acts following the Template Method pattern

  def fetch
    # fetches data from the data source
    # parses fetched data to general format

    # cluster general format: all clusters are array of hashes
    # [
    #   {
    #     cluster_id: string, # cluster id fetched from the source. can be blank if source doesn't return cluster id
    #     domain: string, # domain or ip address
    #     global_volume: integer,
    #     assigned_to: string, # user.cvs_username of the user assigned to cluster
    #     is_pending: boolean, # is the cluster in 2nd or 3rd review phase
    #     categories: array[integer], # categories array set to the cluster
    #     platform: string # cluster's source identifier
    #   }
    # ]
    #
    # !!!NOTE!!!
    # DataFetcher doesn't provide full clusters data due to performance optimization
    # additional data, that should be fetched from 3rd party services is implemented in Clusters::Fetcher
    # see clusters/template/cluster_data_example.rb for full cluster data structure

    raise "#{self.class} should implement .fetch method"
  end
end
