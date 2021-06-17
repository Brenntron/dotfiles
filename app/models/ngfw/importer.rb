class Ngfw::Importer
  class << self
    def import
      handle_import
    end

    private

    def handle_import
      destroy_existing_clusters!
      import_new_clusters
      handle_import if no_other_import_jobs?
    end

    def destroy_existing_clusters!
      # destroys NGFW clusters that should be replaced by new import
      # it also describes specific logic if we need to leave some specific clusters

      NgfwCluster.where.not(status: :pending).delete_all # delete_all should remove all data in one request
    end

    def import_new_clusters
      platform = Platform.where('LOWER(internal_name) LIKE ?', '%ngfw%').first # there is no ILIKE in mysql...
      raise 'NGFW platform not found' if platform.blank?

      pending_clusters = NgfwCluster.pluck(:domain) # all the rest clusters were deleted by destroy_existing_clusters!

      Ngfw::DataFetcher.fetch.each do |ngfw_record|
        # skip pending clusters domains - they are already in progress
        next if pending_clusters.include?(ngfw_record[:domain])

        NgfwCluster.create(
          domain: ngfw_record[:domain],
          traffic_hits: ngfw_record[:traffic_hits],
          platform_id: platform.id
        )
      end
    end

    def no_other_import_jobs?
      DelayedJob.where('handler LIKE ?', "%#{self.name}%").empty?
    end

    handle_asynchronously :handle_import, run_at: Proc.new { Time.zone.tomorrow.beginning_of_day + 16.hours } # run at 4pm next day
  end
end