class CreateDisputeEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_entries do |t|
      t.integer       :dispute_id
      t.string        :ip_address
      t.string        :uri
      t.string        :hostname
      t.string        :entry_type
      t.float         :score
      t.string        :score_type
      t.string        :suggested_disposition
      t.string        :primary_category
      t.string        :tag
      t.string        :top_level_domain
      t.string        :subdomain
      t.string        :domain
      t.string        :path
      t.string        :channel
      t.string        :status
      t.string        :resolution
      t.text          :resolution_comment
      t.timestamps
    end
  end
end
