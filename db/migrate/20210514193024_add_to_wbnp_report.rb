class AddToWbnpReport < ActiveRecord::Migration[5.2]

  def up
    add_column :wbnp_reports, :status_message, :string
    add_column :wbnp_reports, :attempts, :integer
  end

  def down
    remove_column :wbnp_reports, :status_message, :string
    remove_column :wbnp_reports, :attempts, :integer
  end
end
