class AddTypeToBugs < ActiveRecord::Migration[5.1]
  def change
    add_column :bugs, :type, :string, default: 'ResearchBug'

    #also do:
    # update bugs set type = 'EscalationBug' where product = 'Escalations';
  end
end
