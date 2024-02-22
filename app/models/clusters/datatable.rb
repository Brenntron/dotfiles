class Clusters::Datatable < AjaxDatatablesRails::ActiveRecord
  def initialize(params, regex={}, user)
    @user = user
    byebug
    super(params, {})
  end

  def view_columns
    @view_columns ||= {

    }
  end

  def data
    format_data(records)
  end

  def get_raw_records
   
  
    meraki_clusters.union_all(umbrella_clusters).union_all(ngfw_clusters)
  end

  private

  def format_data(clusters)
    byebug
    clusters.map do |cluster|
      # {
      #   cluster_id: cluster['id'],
      #   domain: cluster['domain'],
      #   global_volume: cluster['global_volume'],
      #   is_pending: cluster['status'] == 'pending' ? true : false,
      #   categories: JSON.parse(cluster['category_ids']),
      #   platform: cluster['platform'],
      #   assigned_to: 'mkaban',
      #   is_important: true,
      #   wbrs_score: 3.0,
      #   duplicates: []
      # }

      {
        "cluster_id" => 45084856,
        "domain" => "40.126.28.13",
        "global_volume" => 36329504,
        "cluster_size" => 1,
        "is_pending" => false,
        "categories" => [],
        "platform" => "WSA",
        "assigned_to" => "",
        "is_important" => true,
        "wbrs_score" => -3.0,
        "duplicates" => []
      }
    end
  end
end