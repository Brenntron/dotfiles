class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer  "bugzilla_attachment_id"
      t.string   "filename"
      t.string   "direct_upload_url"
      t.integer  "file_size",              :default => 0
      t.timestamps
    end
    add_reference :attachments, :bug, index: true
    add_reference :attachments, :rule, index: true
    add_reference :attachments, :reference, index: true
    add_index "attachments", ["bugzilla_attachment_id"], :name => "index_attachments_on_bugzilla_attachment_id"
  end
end
