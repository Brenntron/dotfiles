class AddFpColumnsToAllDisputes < ActiveRecord::Migration[5.2]
  def up
    add_column :disputes, :product_platform, :string
    add_column :complaints, :product_platform, :string
    add_column :file_reputation_disputes, :product_platform, :string

    add_column :disputes, :product_version, :string
    add_column :complaints, :product_version, :string
    add_column :file_reputation_disputes, :product_version, :string

    add_column :disputes, :in_network, :boolean
    add_column :complaints, :in_network, :boolean
    add_column :file_reputation_disputes, :in_network, :boolean
  end

  def down
    remove_column :disputes, :product_platform
    remove_column :complaints, :product_platform
    remove_column :file_reputation_disputes, :product_platform

    remove_column :disputes, :product_version
    remove_column :complaints, :product_version
    remove_column :file_reputation_disputes, :product_version

    remove_column :disputes, :in_network
    remove_column :complaints, :in_network
    remove_column :file_reputation_disputes, :in_network
  end
end
