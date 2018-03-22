class AddSecFlagToBugs < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs, :snort_secure, :boolean
  end
end
