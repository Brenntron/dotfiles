class CreateGiblets < ActiveRecord::Migration[5.1]
  def change
    create_table :giblets do |t|
      t.integer :bug_id
      t.string  :name
      t.references :gib, polymorphic: true, index: true 
    end
  end
end
