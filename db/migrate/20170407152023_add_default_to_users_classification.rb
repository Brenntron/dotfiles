class AddDefaultToUsersClassification < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :class_level, :integer, default: 0, null: false
  end
end
