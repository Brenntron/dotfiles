class RemovePublishStatusDefault < ActiveRecord::Migration[5.0]
  def change
    remove_column :rules, :publish_status
    add_column :rules, :publish_status, :string, null: false
  end
end
