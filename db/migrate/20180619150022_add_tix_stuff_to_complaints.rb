class AddTixStuffToComplaints < ActiveRecord::Migration[5.1]
  def change
    add_column :complaints, :ticket_source_key, :integer
    add_column :complaints, :ticket_source, :string
    add_column :complaints, :ticket_source_type, :string
  end
end
