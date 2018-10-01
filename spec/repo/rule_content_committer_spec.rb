describe 'an empty Repo::RuleContentCommitter' do
  before(:context) do
    @username = 'marlpier'
    @relative_filename = 'snort-rules/x11.rules'
    @rule_committer = Repo::RuleContentCommitter.new([], username: @username)
  end

  describe 'for a given path' do
    before(:context) do
      @relative_path = Pathname.new(@relative_filename)
      @absolute_working_path = "#{Rails.root}/extras/working/#{@relative_path}"
      @working_pathname = Pathname.new(@absolute_working_path)
      @working_dir_pathname = @working_pathname.dirname
      @repo_dir_url = "https://repo-test.vrt.sourcefire.com/svn/rules/trunk/#{@relative_path.dirname}/"
    end

    it 'checks out a file' do
      expect(File).to receive(:directory?).with(@working_dir_pathname).and_return(true)
      expect(FileUtils).to receive(:remove_file).with(Pathname.new(@absolute_working_path))
      expect(@rule_committer).to receive(:call_svn).with("up #{@absolute_working_path}")

      @rule_committer.checkout(@relative_path)
    end

    it 'creates working directory' do
      expect(File).to receive(:directory?).with(@working_dir_pathname).and_return(false)
      expect(FileUtils).to receive(:mkpath).with(@working_dir_pathname)
      expect(@rule_committer).to receive(:call_svn).with("co --depth empty #{@repo_dir_url} #{@working_dir_pathname}")
      expect(FileUtils).to receive(:remove_file).with(Pathname.new(@absolute_working_path))
      expect(@rule_committer).to receive(:call_svn).with("up #{@absolute_working_path}")

      @rule_committer.checkout(@relative_path)
    end

    describe 'a Repo::RuleContentCommitter with a RuleFile' do
      before(:context) do
        @relative_filename = 'snort-rules/x11.rules'
        @rule_file = RuleFile.new(@relative_filename)
      end

      it 'calls commit' do
        allow(Repo::RuleContentCommitter).to receive(:collect_rule_files).and_return([@rule_file])
        rule_committer = Repo::RuleContentCommitter.new([], username: 'marlpier')

        # expect(@rule_committer).to receive(:call_svn).with(%Q~commit #{working_file_list} -m "#{svn_commit_message(changed_rules)}"~)
        commit_msg = "#{@username} committed 0 rule(s) from Analyst Console"
        commit_cmd = %Q~commit #{@absolute_working_path} -m "#{commit_msg}"~
        expect(rule_committer).to receive(:call_svn).with(commit_cmd)

        rule_committer.call_commit
      end
    end
  end
end

describe 'a Repo::RuleContentCommitter with content' do
  before(:context) do
    @relative_filename = 'snort-rules/x11.rules'
    @gid = 1
    @sid = 10011
    @rev = 10
    @rule_content = "alert (gid:#{@gid}; sid:#{@sid}; rev: #{@rev};)"
    @rule = FactoryBot.create(:edited_rule,
                               gid: @gid, sid: @sid, rev: @rev, filename: @relative_filename,
                               edit_status: Rule::EDIT_STATUS_EDIT,
                               rule_content: @rule_content)

    @rule_grep_line = "#{@relative_filename}:101:#{@rule_content}"
    @rule_committer = Repo::RuleContentCommitter.new([@rule], username: 'marlpier')
  end

  it 'checks revs' do
    expect(Rule).to receive(:grep_line_from_file).with(@sid, @gid, @relative_filename).and_return(@rule_grep_line)

    @rule_committer.check_all_revs
  end

  describe 'stale content' do
    before(:context) do
      @relative_filename = 'snort-rules/x11.rules'
      @rule_content_repo = "alert (gid:#{@gid}; sid:#{@sid}; rev: #{@rev + 1};)"
      @rule_grep_line_stale = "#{@relative_filename}:101:#{@rule_content_repo}"
    end

    it 'checks revs' do
      expect(Rule).to receive(:grep_line_from_file).with(@sid, @gid, @relative_filename).and_return(@rule_grep_line_stale)

      expect {@rule_committer.check_all_revs}.to raise_error('Cannot commit; revisions do not match the repo')
    end
  end
end

describe 'a file diff' do
  before(:context) do
    @filename = 'trunk/snort-rules/malware.rules'
    @filenames = [ @filename ]
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
  end

  describe 'Commit to svn from outside analyst-console or from analyst-console after commit has completed' do
    it 'loads new rule content' do
      @rule = FactoryBot.create(:synched_rule, sid: 21978, gid: 1, rev: 5)
      allow(Repo::RuleContentCommitter).to receive(:svn_diff_output).with(@filename).and_return(@svn_diff_output)
      allow(File).to receive(:directory?).and_return(true)
      allow(Rule).to receive(:find_from_parser).and_return(@rule)
      allow(@rule).to receive(:associate_references)

      Repo::RuleContentCommitter.repo_notify_relative_filenames(@filenames)

      rule = Rule.by_sid(@rule.sid).first
      expect(rule.rev).to eql(6)
      expect(rule.publish_status).to eq(Rule::PUBLISH_STATUS_SYNCHED)
    end
  end

  describe 'Commit to svn from outside analyst-console for edited rule' do
    it 'marks rule as stale' do
      @rule = FactoryBot.create(:edited_rule, sid: 21978, gid: 1, rev: 5)
      allow(Repo::RuleContentCommitter).to receive(:svn_diff_output).with(@filename).and_return(@svn_diff_output)
      allow(File).to receive(:directory?).and_return(true)
      allow(Rule).to receive(:find_from_parser).and_return(@rule)
      allow(@rule).to receive(:associate_references)

      Repo::RuleContentCommitter.repo_notify_relative_filenames(@filenames)

      rule = Rule.by_sid(@rule.sid).first
      expect(rule.rev).to eql(5)
      expect(rule.publish_status).to eq(Rule::PUBLISH_STATUS_STALE_EDIT)
      expect(rule.rule_content).to eq(@rule.rule_content)
    end
  end

  describe 'Notification from svn hook while analyst-console commit is in progress' do
    it 'updates rule' do
      @rule = FactoryBot.create(:edited_rule, sid: 21978, gid: 1, rev: 5, publish_status: Rule::PUBLISH_STATUS_PUBLISHING)
      allow(Repo::RuleContentCommitter).to receive(:svn_diff_output).with(@filename).and_return(@svn_diff_output)
      allow(File).to receive(:directory?).and_return(true)
      allow(Rule).to receive(:find_from_parser).and_return(@rule)
      allow(@rule).to receive(:associate_references)

      Repo::RuleContentCommitter.repo_notify_relative_filenames(@filenames)

      rule = Rule.by_sid(@rule.sid).first
      expect(rule.rev).to eql(6)
      expect(rule.publish_status).to eq(Rule::PUBLISH_STATUS_SYNCHED)
    end
  end
end

