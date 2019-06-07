class CreateWbnpReports < ActiveRecord::Migration[5.2]
  def change
    create_table :wbnp_reports do |t|
      t.integer      :total_new_cases
      t.integer      :cases_imported
      t.integer      :cases_failed
      t.string       :status
      t.text         :notes, :limit => 16777215
      t.timestamps
    end
  end
end
