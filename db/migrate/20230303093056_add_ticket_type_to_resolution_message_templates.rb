class AddTicketTypeToResolutionMessageTemplates < ActiveRecord::Migration[5.2]
  def up
    add_column :resolution_message_templates, :ticket_type, :string
    ResolutionMessageTemplate.update_all(ticket_type: 'Dispute')
  end

  def down
    remove_column :resolution_message_templates, :ticket_type
  end
end
