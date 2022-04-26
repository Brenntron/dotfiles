class MoreSdrColumns < ActiveRecord::Migration[5.2]
  def up
    add_column :sender_domain_reputation_disputes, :priority, :string
    add_column :sender_domain_reputation_dispute_attachments, :beaker_info, :mediumtext
  end

  def down
    remove_column :sender_domain_reputation_disputes, :priority, :string
    remove_column :sender_domain_reputation_dispute_attachments, :beaker_info, :mediumtext
  end
end
