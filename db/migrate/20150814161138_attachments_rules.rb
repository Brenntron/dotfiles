class AttachmentsRules < ActiveRecord::Migration[4.2]
  def change
    create_table :attachments_rules, id: false do |t|
      t.integer :attachment_id
      t.integer :rule_id
    end
  end
end
