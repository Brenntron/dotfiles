class ClusterDatatable < AjaxDatatablesRails::Base


  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||={
      id:       {source: "Cluster.cluster_id", cond: :eq, searchable: true, orderable: true},
      # age:      {source: "Cluster.age", cond: :eq, searchable: true, orderable: true},
      domain:   {source: "Cluster.domain", cond: :eq, searchable: true, orderable: true},
      # cluster_entries_count: {source: "Cluster.entry_count", cond: :eq, searchable: false, orderable: true},
      # customer_name: {source: "Complaint.customer_name", cond: :eq, searchable: true, orderable: true},
      global_volume: {source: "Cluster.global_volume", cond: :eq, searchable: true, orderable: true},
      age:  {source: "Cluster.ctime", cond: :eq, searchable: true, orderable: true},
    }
  end

  def data
    records.map do |record|
      {
          id:         record.cluster_id,
          age:        record.ctime,
          domain:     record.domain,
          # entry_count: record.entries.count,
          global_volume:     record.global_volume,
      }
    end
  end

  private

  def get_raw_records
    Cluster.all
  end

end
