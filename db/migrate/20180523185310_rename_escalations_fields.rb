class RenameEscalationsFields < ActiveRecord::Migration[5.1]
  def change
    # Maybe I did not have to renamed the escalations table,
    # but it started to work around the time I tried renaming it,
    # and I think this name for the table and model is clearer.
    rename_table('escalations', 'escalation_links')
    rename_column :escalation_links, :snort_escalation_research_bug_id, :snort_escalation_bug_id
    rename_column :escalation_links, :snort_research_escalation_bug_id, :snort_research_bug_id
  end
end
