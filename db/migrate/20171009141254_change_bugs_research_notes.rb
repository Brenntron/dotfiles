class ChangeBugsResearchNotes < ActiveRecord::Migration[5.1]
  def change
    change_column :bugs, :research_notes, :text
  end
end
