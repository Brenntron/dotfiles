class AddTypeToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :type, :string, default: "Task"
  end
end
