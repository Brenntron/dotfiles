class ChangeTaskResultType < ActiveRecord::Migration[5.1]
  def self.up
    change_column :tasks, :result, :text, limit: 16.megabytes - 1
  end

  def self.down
    change_column :tasks, :result, :text
  end
end
