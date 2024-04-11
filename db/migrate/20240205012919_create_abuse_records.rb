class CreateAbuseRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :abuse_records do |t|
      t.integer     :complaint_entry_id
      t.string      :source
      t.string      :report_ident
      t.text        :result
      t.text        :report_submitted
      t.string      :submitter
      t.text        :url
      t.timestamps
    end
  end
end
