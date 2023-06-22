class EscalationTicket < ApplicationRecord

  def self.create_bug(bug_attrs = {})

    new_ticket = EscalationTicket.new
    new_ticket.ticket_data = bug_attrs.to_json
    new_ticket.save

    new_ticket

  end
end
