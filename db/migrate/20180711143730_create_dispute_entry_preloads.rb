class CreateDisputeEntryPreloads < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_entry_preloads do |t|
      t.references :dispute_entry, foreign_key: true
      t.text :xbrs_history, limit: 4294967295
      t.text :crosslisted_urls, limit: 4294967295
      t.text :virustotal, limit: 4294967295
      t.text :wlbl, limit: 4294967295

      t.timestamps
    end
  end
end
