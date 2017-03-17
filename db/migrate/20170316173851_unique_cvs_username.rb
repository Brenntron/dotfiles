class UniqueCvsUsername < ActiveRecord::Migration[5.0]
  def change
    change_column(:users, :cvs_username, :string, null: false)
    add_index(:users, :cvs_username, unique: true)
  end
end
