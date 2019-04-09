class AddThreatGridPrivate < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :threatgrid_private, :boolean
    add_column :file_reputation_disputes, :has_sample, :boolean
  end
end
