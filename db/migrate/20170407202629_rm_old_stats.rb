class RmOldStats < ActiveRecord::Migration[5.0]
  def change
    change_table(:alerts) do |tab|
      tab.remove :average_check, :average_match, :average_nonmatch
    end
    change_table(:rules) do |tab|
      tab.remove :average_check, :average_match, :average_nonmatch
    end
  end
end
