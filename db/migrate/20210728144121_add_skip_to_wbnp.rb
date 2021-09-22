class AddSkipToWbnp < ActiveRecord::Migration[5.2]
  def up
    add_column :wbnp_reports, :cases_skipped, :integer
  end

  def down
    remove_column :wbnp_reports, :cases_skipped, :integer
  end
end
