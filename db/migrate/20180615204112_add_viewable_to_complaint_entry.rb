class AddViewableToComplaintEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :complaint_entries, :viewable, :boolean, null: false, default: true
  end
end
