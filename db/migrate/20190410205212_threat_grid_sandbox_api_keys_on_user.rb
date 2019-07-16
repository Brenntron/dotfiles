class ThreatGridSandboxApiKeysOnUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :threatgrid_api_key, :string
    add_column :users, :sandbox_api_key, :string
  end
end