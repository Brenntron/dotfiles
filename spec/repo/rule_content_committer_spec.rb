describe "a Repo::RuleContentCommitter" do
  before(:context) do
    @rule_committer = Repo::RuleContentCommitter.new([], username: 'marlpier')
    @relative_path = Pathname.new('snort-rules/x11.rules')
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
end

describe Repo::RuleContentCommitter do
  it 'passes a test' do
    expect(true).to be_truthy
  end
end
