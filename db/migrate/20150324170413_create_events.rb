class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string   :user
      t.string   :action
      t.string   :description
      t.integer  :progress
      t.timestamps
    end
  end
end
