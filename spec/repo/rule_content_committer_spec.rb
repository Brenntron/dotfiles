describe Repo::RuleContentCommitter do
  describe 'prescreening' do
    before(:context) do
      @rule_synched = FactoryGirl.create(:synched_rule)
      @rule_stale = FactoryGirl.create(:stale_rule)
      @rule_edited = FactoryGirl.create(:edited_rule)
      @rule_incomplete = FactoryGirl.create(:edited_rule)
      @rule_complete = FactoryGirl.create(:edited_rule)
      FactoryGirl.create(:rule_doc, rule: @rule_complete)
      @bug_embargo = FactoryGirl.create(:bug, liberty: Bug::LIBERTY_EMBARGO)
      @bug = FactoryGirl.create(:bug)
      @user = FactoryGirl.create(:user)
    end

    it 'prescreens bug embargo state' do

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_synched], nil, bug: @bug_embargo)
      end.to raise_error('bug is in EMBARGO state')
    end

    it 'prescreens unknown user' do

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_synched], nil, bug: @bug)
      end.to raise_error('unknown user')
    end

    it 'prescreens unchanged rules' do

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_synched], @user, bug: @bug)
      end.to raise_error('Some of those rules are unchanged!')
    end

    it 'prescreens stale rules' do

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_stale], @user, bug: @bug)
      end.to raise_error('Some of those rules cannot be committed because they have changed in the repo!')
    end

    it 'prescreens untested rules' do

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_edited], @user, bug: @bug)
      end.to raise_error('Cannot commit with untested rules!')
    end

    it 'prescreens incomplete docs' do
      @bug.rules << @rule_incomplete
      @rule_incomplete.bugs_rules.update_all(tested: true)

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_incomplete], @user, bug: @bug)
      end.to raise_error('Cannot commit with incomplete rule docs!')
    end

    it 'prescreens good commits' do
      @bug.rules << @rule_complete
      @rule_complete.bugs_rules.update_all(tested: true)

      expect do
        Repo::RuleContentCommitter.prescreen!([@rule_complete], @user, bug: @bug)
      end.to_not raise_error
    end
  end
end

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
    @rule = Rule.new(gid: @gid, sid: @sid, rev: @rev, filename: @relative_filename,
                     edit_status: Rule::EDIT_STATUS_EDIT,
                     rule_content: @rule_content)
    @rule = FactoryGirl.create(:rule,
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
