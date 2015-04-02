class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.integer  "gid"
      t.integer  "sid"
      t.integer  "rev"
      t.string   "message"
      t.text     "detection"
      t.string   "state"
      t.timestamps
      t.float    "average_check"
      t.float    "average_match"
      t.float    "average_nonmatch"
      t.boolean  "tested",           :default => false
    end
    add_reference :rules, :bug, index: true
    add_index "rules", ["gid", "sid"], :name => "index_rules_on_gid_and_sid", :unique => true
  end

end
