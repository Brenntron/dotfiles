class AddAcknowledgedToBugs < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs, :acknowledged, :boolean
  end
end
