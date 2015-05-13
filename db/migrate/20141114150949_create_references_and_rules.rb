class CreateReferencesAndRules < ActiveRecord::Migration
  def change
    create_table :references do |t|
      t.string :data
      t.timestamps
    end
    add_reference :references, :rule, index: true
    add_reference :references, :bug, index: true

    create_table :rules do |t|
      t.text     "rule_content"
      t.string   "connection"
      t.string   "message"
      t.string   "flow"
      t.text     "detection"
      t.string   "metadata"
      t.string   "class_type"
      t.integer  "gid"
      t.integer  "sid",              unique: true
      t.integer  "rev"
      t.string   "state"
      t.float    "average_check"
      t.float    "average_match"
      t.float    "average_nonmatch"
      t.boolean  "tested",           default: false
      t.boolean  "committed",        default: false
      t.timestamps
    end

    add_reference :rules, :reference, index: true
    add_reference :rules, :bug, index: true
    add_index "rules", ["gid", "sid"], :name => "index_rules_on_gid_and_sid", :unique => true

    create_table :references_rules, id: false do |t|
      t.belongs_to :reference, index: true
      t.belongs_to :rule, index: true
    end

  end

end
