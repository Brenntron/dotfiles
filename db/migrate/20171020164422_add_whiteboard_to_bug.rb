class AddWhiteboardToBug < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs, :whiteboard, :string
  end
end
