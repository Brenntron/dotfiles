class RenameEscalationsFields < ActiveRecord::Migration[5.1]
  def change
    rename_table('escalations', 'escalation_links')
    rename_column :escalation_links, :snort_escalation_research_bug_id, :snort_escalation_bug_id
    rename_column :escalation_links, :snort_research_escalation_bug_id, :snort_research_bug_id
  end
end
