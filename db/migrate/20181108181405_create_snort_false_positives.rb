class CreateSnortFalsePositives < ActiveRecord::Migration[5.1]
  def change
    create_table :snort_false_positives do |t|
      t.integer "bug_id"
      t.string "user_email"
      t.string "sid"
      t.text "description"
      t.string "source_authority"
      t.string "source_key"
      t.string "os"
      t.string "version"
      t.string "built_from"
      t.string "pcap_lib"
      t.string "cmd_line_options"
      t.timestamps
    end
    add_index :snort_false_positives, ["source_authority", "source_key"]

  end
end


