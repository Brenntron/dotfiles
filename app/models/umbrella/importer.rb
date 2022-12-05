class Umbrella::Importer
  class << self
    def import(date = nil)
      handle_import(date) if no_other_import_jobs? # this runs the background job
    end

    def import_without_delay(date = nil)
      destroy_existing_clusters!
      import_new_clusters(date)
    end

    private

      def destroy_existing_clusters!
        # destroys Umbrella clusters that should be replaced by new import
        # it also describes specific logic if we need to leave some specific clusters
        # destroys everything except assigned or pending clusters

        assigned_domains = ClusterAssignment.fetch_all_assignments.pluck(:domain)
        UmbrellaCluster.where.not(status: :pending, domain: assigned_domains).delete_all
      end

      def handle_import(date)
        destroy_existing_clusters!
        import_new_clusters(date)
      end
      handle_asynchronously :handle_import, run_at: Proc.new { Time.zone.today.beginning_of_day + 20.hours } # run at 8pm UTC today

      def import_new_clusters(date)
        platform = Platform.where('LOWER(internal_name) LIKE ?', '%umbrella%').first

        raise 'Umbrella platform not found' if platform.blank?

        Umbrella::DataFetcher.fetch(date).each do |umbrella_record|
          domain = umbrella_record[:domain].delete_prefix('www.')
          UmbrellaCluster.find_or_create_by(domain: domain, platform_id: platform.id)
        end
      end

      def no_other_import_jobs?
        DelayedJob.where('handler LIKE ?', "%#{self.name}%").empty?
      end
  end
end