class PopulateWebCatClusters < ActiveRecord::Migration[6.1]
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

    # Perform bulk inserts for each data set
    WebCatCluster.insert_all!(umbrella_data)
    WebCatCluster.insert_all!(ngfw_data)
    WebCatCluster.insert_all!(meraki_data)
  end

  def down
    WebCatCluster.delete_all
  end
end
