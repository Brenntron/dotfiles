class Strict < ActiveRecord::Migration[5.1]
  def change
    remove_index    :attachments, name: :index_attachments_on_reference_id
    rename_column   :attachments, :reference_id, :unused_reference_id
    rename_table    :attachments_exploits, :unused_attachments_exploits
    rename_table    :attachments_rules, :unused_attachments_rules
    rename_column   :bugs, :gid, :unused_gid
    rename_column   :bugs, :sid, :unused_sid
    rename_column   :bugs, :rev, :unused_rev
    remove_index    :bugs, name: :index_bugs_on_reference_id
    rename_column   :bugs, :reference_id, :unused_reference_id
    remove_index    :bugs, name: :index_bugs_on_rule_id
    rename_column   :bugs, :rule_id, :unused_rule_id
    # remove_index    :bugs, name: :index_bugs_on_attachment_id
    rename_column   :bugs, :attachment_id, :unused_attachment_id
    rename_column   :bugs_rules, :svn_result_output, :unused_svn_result_output
    rename_column   :bugs_rules, :svn_result_code, :unused_svn_result_code
    rename_column   :exploit_types, :exploit_id, :unused_exploit_id
    rename_column   :exploits, :reference_id, :unused_reference_id
    rename_table    :references_rules, :unused_references_rules
    remove_index    :roles_users, name: :index_roles_users_on_user_id
    rename_column   :rules, :tested, :unused_tested
  end
end
