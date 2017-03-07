class CreateReferencesAndRules < ActiveRecord::Migration
  def change
    create_table :references do |t|
      t.string :reference_data
      t.belongs_to :reference_type, index: true
      t.belongs_to :bug, index: true
      t.belongs_to :exploit, index:true
      t.timestamps
    end
    # add_reference :references, :rule, index: true
    # add_reference :references, :bug, index: true

    create_table :rules do |t|
      t.text     "rule_content"
      t.text     "rule_parsed"
      t.text     "rule_warnings"
      t.text     "rule_failures"
      t.text     "cvs_rule_content"
      t.text     "cvs_rule_parsed"
      t.text     "connection"
      t.string   "message"
      t.string   "flow"
      t.text     "detection"
      t.string   "metadata"
      t.string   "class_type"
      t.integer  "gid"
      t.integer  "sid"
      t.integer  "rev"
      t.string   "state"
      t.string   "publish_status", null: false, default: "SYNCHED"
      t.float    "average_check"
      t.float    "average_match"
      t.float    "average_nonmatch"
      t.boolean  "tested",           default: false
      t.boolean  "committed",        default: false
      t.timestamps
    end

    add_reference :rules, :task, index: true
    add_reference :rules, :rule_category, index: true
    add_index :rules, [:gid, :sid], :name => "index_rules_gid_and_sid", :unique => true

    create_table :references_rules, id: false do |t|
      t.belongs_to :reference, index: true
      t.belongs_to :rule, index: true
    end

  end

end
