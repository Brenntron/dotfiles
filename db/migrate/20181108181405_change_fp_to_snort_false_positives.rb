class ChangeFpToSnortFalsePositives < ActiveRecord::Migration[5.1]
  def change
    rename_table :false_positives, :snort_false_positives
  end
end

