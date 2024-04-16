class PopulateWebCatClusters < ActiveRecord::Migration[6.1]
  CHUNK_SIZE = 5000

  def up
    umbrella_data = UmbrellaCluster.all.map do |cluster|
      {
        domain: cluster.domain,
        platform_id: cluster.platform_id,
        category_ids: cluster.category_ids,
        status: cluster.status,
        traffic_hits: cluster.traffic_hits,
        comment: cluster.comment,
        cluster_type: 'Umbrella',
        created_at: cluster.created_at,
        updated_at: cluster.updated_at
      }
    end

    ngfw_data = NgfwCluster.all.map do |cluster|
      {
        domain: cluster.domain,
        platform_id: cluster.platform_id,
        category_ids: cluster.category_ids,
        status: cluster.status,
        traffic_hits: cluster.traffic_hits,
        comment: cluster.comment,
        cluster_type: 'NGFW',
        created_at: cluster.created_at,
        updated_at: cluster.updated_at
      }
    end

    meraki_data = MerakiCluster.all.map do |cluster|
      {
        domain: cluster.domain,
        platform_id: cluster.platform_id,
        category_ids: cluster.category_ids,
        status: cluster.status,
        traffic_hits: cluster.traffic_hits,
        comment: cluster.comment,
        cluster_type: 'Meraki',
        created_at: cluster.created_at,
        updated_at: cluster.updated_at
      }
    end


    # Process Umbrella data in chunks
    umbrella_data.each_slice(CHUNK_SIZE) do |chunk|
      WebCatCluster.insert_all!(chunk)
    end

    # Process NGFW data in chunks
    ngfw_data.each_slice(CHUNK_SIZE) do |chunk|
      WebCatCluster.insert_all!(chunk)
    end

    # Process Meraki data in chunks
    meraki_data.each_slice(CHUNK_SIZE) do |chunk|
      WebCatCluster.insert_all!(chunk)
    end
  end

  def down
    WebCatCluster.delete_all
  end
end
