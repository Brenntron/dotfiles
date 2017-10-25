class ChangeTextColumns < ActiveRecord::Migration[5.1]
  def change
   change_column :bugs, :description, :text
   change_column :bugs, :summary, :text
  end
end
