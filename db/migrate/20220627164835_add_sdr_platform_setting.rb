class AddSdrPlatformSetting < ActiveRecord::Migration[5.2]
  def up
    add_column :platforms, :senderdomain, :boolean
  end

  def down

  end
end
