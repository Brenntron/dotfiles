class NgfwClustersDomainToText < ActiveRecord::Migration[5.2]
  def change
      change_column :ngfw_clusters, :domain, :text
  end
end
