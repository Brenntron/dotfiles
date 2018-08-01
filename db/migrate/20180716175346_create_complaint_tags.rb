class CreateComplaintTags < ActiveRecord::Migration[5.1]
  def change
    create_table :complaint_tags do |t|
      t.string :name
      t.timestamps
    end
  end
end
