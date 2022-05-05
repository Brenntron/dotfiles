class BeakerForSdr < ActiveRecord::Migration[5.2]
  def up
    add_column :sender_domain_reputation_disputes, :beaker_info, :mediumtext
  end

  def down
    remove_column :sender_domain_reputation_disputes, :beaker_info, :mediumtext
  end
end
