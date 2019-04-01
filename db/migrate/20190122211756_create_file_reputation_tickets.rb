class CreateFileReputationTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :file_reputation_tickets do |t|
      t.references :customer
      t.string :status
      t.string :source
      t.string :platform
      t.string :description
      t.references :reputation_file
    end
  end
end
