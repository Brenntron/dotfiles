class FixAmpColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :amp_naming_conventions, :public_engine_description, :private_engine_description
  end
end
