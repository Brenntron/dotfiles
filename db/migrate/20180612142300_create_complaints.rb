class CreateComplaints < ActiveRecord::Migration[5.1]
  def change
    create_table :complaints do |t|
      t.string       :tag
      t.string       :channel
      t.string       :status
      t.text         :description
      t.string       :added_through
      t.datetime     :complaint_assigned_at
      t.datetime     :complaint_closed_at
      t.string       :resolution
      t.text         :resolution_comment
      t.string       :customer
      t.string       :region
      t.integer      :user_id
      t.timestamps
    end
  end
end
