class CreateReferences < ActiveRecord::Migration
  def change
    create_table :references do |t|
      t.string  "data"
      t.string  "name"
      t.string  "description"
      t.string  "validation"
      t.string  "bugzilla_format"
      t.string  "example"
      t.string  "rule_format"
      t.string  "url"
      t.integer :bug_id
      t.timestamps
    end
    add_reference :references, :rule, index: true
  end
end
