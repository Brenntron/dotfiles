class CreateFalsePositives < ActiveRecord::Migration[5.1]
  def change
    create_table :false_positives do |t|
      t.timestamps
      t.string :user_email
      t.string :sid
      t.string :description
      t.string :source_authority
      t.string :source_key
      t.string :os
      t.string :version
      t.string :built_from
      t.string :pcap_lib
      t.string :cmd_line_options
    end
    add_index(:false_positives, [:source_authority, :source_key], unique: true)
  end
end
