class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer  "bugzilla_attachment_id"
      t.string   "file_name"
      t.string   "summary"
      t.string   "content_type"
      t.string   "direct_upload_url"
      t.integer  "size",              :default => 0
      t.integer  "creator"
      t.boolean  "is_obsolete", :default => false
      t.boolean  "is_private", :default => false
      t.boolean  "minor_update", :default => false
      t.timestamps
    end

    add_reference :attachments, :bug, index: true
    add_reference :attachments, :rule, index: true
    add_reference :attachments, :reference, index: true
    add_reference :attachments, :job, index: true
    add_index "attachments", ["bugzilla_attachment_id"], :name => "index_attachments_on_bugzilla_attachment_id"
  end
end
