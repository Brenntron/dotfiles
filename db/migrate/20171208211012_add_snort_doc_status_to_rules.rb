class AddSnortDocStatusToRules < ActiveRecord::Migration[5.1]
  def change
    add_column :rules, :snort_doc_status, :string, default: 'NOTYET'
  end
end
