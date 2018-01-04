class AddFailCountToReferences < ActiveRecord::Migration[5.1]
  def change
    add_column :references, :fail_count, :integer, default: 0
  end
end
