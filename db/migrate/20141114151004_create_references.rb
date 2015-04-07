class CreateReferences < ActiveRecord::Migration
  def change
    create_table :references do |t|
      t.string :data
      t.timestamps
    end
    add_reference :references, :rule, index: true
    add_reference :references, :bug, index: true
  end
end
