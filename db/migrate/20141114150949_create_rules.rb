class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.text     "rule_content"
      t.string   "connection"
      t.string   "message"
      t.string   "flow"
      t.text     "detection"
      t.string   "metadata"
      t.string   "class_type"
      t.integer  "gid"
      t.integer  "sid", :unique => true
      t.integer  "rev"
      t.string   "state"
      t.float    "average_check"
      t.float    "average_match"
      t.float    "average_nonmatch"
      t.boolean  "tested",           :default => false
      t.timestamps
    end

    add_reference :rules, :reference, index: true
    add_reference :rules, :bug, index: true
    add_index "rules", ["gid", "sid"], :name => "index_rules_on_gid_and_sid", :unique => true
  end

end
