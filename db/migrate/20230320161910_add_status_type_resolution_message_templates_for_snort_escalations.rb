class AddStatusTypeResolutionMessageTemplatesForSnortEscalations < ActiveRecord::Migration[5.2]
  def up
    add_column :resolution_message_templates, :resolution_type, :string
    add_column :resolution_message_templates, :creator_id, :bigint
    add_column :resolution_message_templates, :editor_id, :bigint
  end

  def down
    remove_column :resolution_message_templates, :resolution_type
    remove_column :resolution_message_templates, :creator_id
    remove_column :resolution_message_templates, :editor_id
  end
end
