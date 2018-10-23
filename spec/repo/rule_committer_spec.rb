describe Repo::RuleCommitter do
  before(:context) do
    @relative_filename = 'snort-rules/malware.rules'
    @gid = 1
    @sid = 10011
    @rev = 10
    @rule_content = "alert (gid:#{@gid}; sid:#{@sid}; rev: #{@rev};)"
    @rule = FactoryBot.create(:edited_rule,
                               gid: @gid, sid: @sid, rev: @rev, filename: @relative_filename,
                               edit_status: Rule::EDIT_STATUS_EDIT,
                               rule_content: @rule_content)
    @rule_file = RuleFile.new(@relative_filename)
    @user = FactoryBot.create(:fake_user)
    @svn_result_output = <<eos
Sending        extras/working/snort-rules/malware.rules
Transmitting file data .done
Committing transaction...
svn: E165001: Commit failed (details follow):
svn: E165001: Commit blocked by pre-commit hook (exit code 199) with output:

Rules have been successfully committed. Please ignore 'exit code 199'!
In your working copy, please remove the file you committed just now, then do an 'svn update'.
USER    : acweb
NEW     : 2
UPDATED : 0
eos
  end

  it 'calls synch_failsafe when commit does not load committed rule' do
    allow(Repo::RuleContentCommitter).to receive(:collect_rule_files).and_return([@rule_file])
    @committer = Repo::RuleCommitter.new([@rule], xmlrpc: nil, user: @user)
    allow(@committer).to receive(:event_start)
    expect(@committer.content_committer).to receive(:commit_rule_content) do
      @committer.content_committer.instance_variable_set(:@success, true)
      @svn_result_output
    end
    expect(@rule_file).to receive(:synch_failsafe)
    allow(@committer).to receive(:commit_bugzilla)

    @committer.locked_commit(bugzilla_comment: 'Here is a bugzilla comment.')

  end

  it 'skips synch_failsafe when commit loads committed rule' do
    @svn_diff_output = <<eos
Index: extras/snort/snort-rules/malware.rules
===================================================================
--- extras/snort/snort-rules/malware.rules     (revision 51896)
+++ extras/snort/snort-rules/malware.rules     (working copy)
@@ -19,52 +19,52 @@
 #-------------------
 
-# alert tcp $HOME_NET any -> $EXTERNAL_NET 5447 (msg:"MALWARE-BACKDOOR Win.Backdoor.Nervos variant outbound connection"; flow:to_server,established; content:"|01 01|"; depth:2; content:"|00 00|"; depth:2; offset:62; pcre:"/^((\\x82\\x01)|(\\xe6\\x01)|(\\x4a\\x02)|(\\x98\\x08)|(\\xd8\\x21))\\x00\\x00/R"; flowbits:set,trojan.nervos; metadata:impact_flag red, policy security-ips drop; classtype:trojan-activity; sid:21978; rev:5;)
-# alert tcp $HOME_NET any -> $EXTERNAL_NET 5447 (msg:"MALWARE-BACKDOOR Win.Backdoor.Nervos variant outbound connection"; flow:to_server,established; content:"|01 01|"; depth:2; content:"|00 00|"; depth:2; offset:62; pcre:"/^((\\x82\\x01)|(\\xe6\\x01)|(\\x4a\\x02)|(\\x98\\x08)|(\\xd8\\x21))\\x00\\x00/R"; flowbits:set,trojan.nervos; metadata:impact_flag red, policy security-ips drop; classtype:trojan-activity; sid:21978; rev:5;)
+# alert tcp $HOME_NET any -> $EXTERNAL_NET 5447 (msg:"MALWARE-BACKDOOR Win.Backdoor.Nervos variant outbound connection"; flow:to_server,established; content:"|01 01|"; depth:2; content:"|00 00|"; depth:2; offset:62; pcre:"/^((\\x82\\x01)|(\\xe6\\x01)|(\\x4a\\x02)|(\\x98\\x08)|(\\xd8\\x21))\\x00\\x00/R"; flowbits:set,trojan.nervos; metadata:impact_flag red; classtype:trojan-activity; sid:21978; rev:6;)
 # alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"MALWARE-BACKDOOR JSP webshell backdoor detected"; flow:to_server,established; content:"/zecmd/zecmd.jsp?"; fast_pattern:only; http_uri; metadata:impact_flag red, policy balanced-ips drop, policy security-ips drop, service http; classtype:trojan-activity; sid:38719; rev:1;)
 # alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"MALWARE-BACKDOOR JSP webshell backdoor detected"; flow:to_server,established; content:".jsp?ppp="; fast_pattern:only; http_uri; metadata:impact_flag red, policy balanced-ips drop, policy security-ips drop, service http; classtype:trojan-activity; sid:39058; rev:1;)
eos
    allow(Repo::RuleContentCommitter).to receive(:collect_rule_files).and_return([@rule_file])
    @committer = Repo::RuleCommitter.new([@rule], xmlrpc: nil, user: @user)
    allow(@committer).to receive(:event_start)
    allow(Repo::RuleContentCommitter).to receive(:svn_diff_output).with(@relative_filename).and_return(@svn_diff_output)
    allow(File).to receive(:directory?).and_return(true)
    allow(Rule).to receive(:find_from_parser).and_return(@rule)
    expect(@committer.content_committer).to receive(:commit_rule_content) do
      @committer.content_committer.instance_variable_set(:@success, true)
      Repo::RuleContentCommitter.repo_notify_relative_filenames([ @relative_filename ])
      @svn_result_output
    end
    expect(@rule_file).to_not receive(:synch_failsafe)
    allow(@committer).to receive(:commit_bugzilla)

    @committer.locked_commit(bugzilla_comment: 'Here is a bugzilla comment.')

  end
end

