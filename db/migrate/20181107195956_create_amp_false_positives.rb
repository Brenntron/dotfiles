class CreateAmpFalsePositives < ActiveRecord::Migration[5.1]
  def change
    create_table :amp_false_positives do |t|
      t.string "sha256"
      t.string "customer"
      t.string "source"
      t.string "justification"
      t.string "product"
      t.integer "sr_id"
      t.text "payload"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    add_index :amp_false_positives, [ 'payload'], length: 15
    add_index :amp_false_positives, [ 'sha256']
  end
end

