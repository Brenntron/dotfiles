class Umbrella::Importer
  class << self
    def import(date = nil)
      handle_import(date) if no_other_import_jobs? # this runs the background job
    end

    def import_without_delay(date = nil)
      import_new_clusters(date)
    end

    private

      def handle_import(date)
        import_new_clusters(date)
      end
      handle_asynchronously :handle_import, run_at: Proc.new { Time.zone.today.beginning_of_day + 20.hours } # run at 8pm UTC today

      def import_new_clusters(date)
        platform = Platform.where('LOWER(internal_name) LIKE ?', '%umbrella%').first

        raise 'Umbrella platform not found' if platform.blank?

        Umbrella::DataFetcher.fetch(date).each do |umbrella_record|
          UmbrellaCluster.find_or_create_by(domain: umbrella_record[:domain], platform_id: platform.id)
        end
      end

      def no_other_import_jobs?
        DelayedJob.where('handler LIKE ?', "%#{self.name}%").empty?
      end
  end
end