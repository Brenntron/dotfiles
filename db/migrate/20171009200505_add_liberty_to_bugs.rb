class AddLibertyToBugs < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs, :liberty, :string, default: "CLEAR"
  end
end
