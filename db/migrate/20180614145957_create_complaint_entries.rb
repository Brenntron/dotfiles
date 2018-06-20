class CreateComplaintEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :complaint_entries do |t|
      t.integer      :complaint_id
      t.string       :tag
      t.string       :subdomain
      t.string       :domain
      t.string       :path
      t.integer      :wbrs_score
      t.string       :url_primary_category
      t.string       :resolution
      t.text         :resolution_comment
      t.datetime     :complaint_entry_resolved_at
      t.string       :status
      t.timestamps
    end
  end
end
