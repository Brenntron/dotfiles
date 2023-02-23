class CreateEscalationTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :escalation_tickets do |t|
      t.mediumtext :ticket_data
      t.timestamps
    end
  end
end
