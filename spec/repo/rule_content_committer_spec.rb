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
