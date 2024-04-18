class Clusters::Importer
  PLAFORM_SOURCES = {
    'Umbrella' => 'Umbrella',
    'SecureFirewall' => 'NGFW',
    'Meraki' => 'Meraki'
  }.freeze

  class << self
    def import
      handle_import(date) if no_other_import_jobs? # this runs the background job
    end

    def import_without_delay
      destroy_existing_clusters!
      import_new_clusters
    end

    private

    def destroy_existing_clusters!
      # destroys Umbrella and NGFW clusters that should be replaced by new import
      # it also describes specific logic if we need to leave some specific clusters
      # destroys everything except assigned or pending clusters

      assigned_domains = ClusterAssignment.fetch_all_assignments.pluck(:domain)
      WebCatCluster.where.not(status: :pending, domain: assigned_domains).delete_all
    end

    def handle_import
      destroy_existing_clusters!
      import_new_clusters
    end

    def import_new_clusters
      ngwf_platform, umbrella_platform, meraki_platform = [Platform.ngfw, Platform.umbrella, Platform.meraki]
      raise 'NGFW platform not found' if ngwf_platform.blank?
      raise 'Umbrella platform not found' if umbrella_platform.blank?
      raise 'Meraki platform not found' if meraki_platform.blank?

      platform_ids = {
        'SecureFirewall' => ngwf_platform.id,
        'Umbrella' => umbrella_platform.id,
        'Meraki' => meraki_platform.id
      }

      data = Clusters::DataFetcher.fetch
      # all the rest clusters were deleted by destroy_existing_clusters!
      pending_cluster_domains = WebCatCluster.pluck(:domain)
      data.each do |cluster|
        next if pending_cluster_domains.include?(cluster[:domain])
        next unless PLAFORM_SOURCES.keys.include?(cluster['platform'])

        data = {
          domain: cluster['cluster_domain'].delete_prefix('www.'),
          platform_id: platform_ids[cluster['platform']],
          traffic_hits: cluster['global_volume'],
          cluster_type: PLAFORM_SOURCES[cluster['platform']]
        }

        WebCatCluster.find_or_create_by(data)
      end
    end

    handle_asynchronously :handle_import, run_at: Proc.new { Time.zone.today.beginning_of_day + 19.hours } # run at 7pm UTC today

    def no_other_import_jobs?
      DelayedJob.where('handler LIKE ?', "%#{self.name}%").empty?
    end
  end
end