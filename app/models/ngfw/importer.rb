class Ngfw::Importer
  class << self
    def import
      destroy_existing_clusters!
      import_new_clusters
    end

    private

    def destroy_existing_clusters!
      # destroys NGFW clusters that should be replaced by new import
      # it also describes specific logic if we need to leave some specific clusters

      NgfwCluster.delete_all # delete_all shoudl remove all data in one request
    end

    def import_new_clusters
      ngfw_data = Ngfw::DataFetcher.fetch
      NgfwCluster.create(ngfw_data)
      # ngfw_data.each do |ngfw_record|
      #   NgfwCluster.create(domain: ngfw_record[:domain], traffic_hits: ngfw_record[:count])
      # end
    end
  end
end
