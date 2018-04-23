class CreateDisputeEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_entries do |t|
      t.integer       :dispute_id
      t.string        :ip_address
      t.string        :uri
      t.string        :hostname
      t.string        :entry_type
      t.integer       :score
      t.string        :score_type
      t.string        :suggested_disposition
      t.string        :primary_category
      t.timestamps
    end
  end
end
