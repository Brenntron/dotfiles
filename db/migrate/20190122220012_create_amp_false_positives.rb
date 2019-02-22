class CreateAmpFalsePositives < ActiveRecord::Migration[5.2]
  def change
    create_table :amp_false_positives do |t|
      t.integer "sr_id"
      t.text "payload"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.references :file_reputation_ticket
    end
    add_index :amp_false_positives, [ 'payload'], length: 15
  end
end
