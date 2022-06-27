class AddSdrPlatformSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :platforms, :senderdomain, :boolean
  end
end
