class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string   "cvs_username"
      t.boolean  "committer",    :default => false
      t.timestamps
    end
  end
end
