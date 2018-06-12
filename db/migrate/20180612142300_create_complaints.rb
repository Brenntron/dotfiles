class CreateComplaints < ActiveRecord::Migration[5.1]
  def change
    create_table :complaints do |t|
      t.string       :tag
      t.string       :subdomain
      t.string       :domain
      t.string       :path
      t.string       :channel
      t.string       :status
      t.text         :description
      t.string       :added_through
      t.datetime     :complaint_opened_at
      t.datetime     :complaint_closed_at
      t.datetime     :complaint_accepted_at
      t.datetime     :complaint_resolved_at
      t.string       :resolution
      t.text         :resolution_comment
      t.string       :customer
      t.string       :region
      t.integer      :assigned_to
      t.string       :url_primary_category
      t.integer      :wbrs_score
      t.timestamps
    end
  end
end
