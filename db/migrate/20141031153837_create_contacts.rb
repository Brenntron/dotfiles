class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :about
      t.string :avatar
      t.timestamps
    end
  end
end
