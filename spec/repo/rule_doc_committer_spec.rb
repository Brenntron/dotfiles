describe Repo::RuleDocCommitter do
  before(:context) do
    @username = 'marlpier'
    @rule = FactoryGirl.create(:synched_rule, publish_status: Rule::PUBLISH_STATUS_PUBDOC)
    FactoryGirl.create(:rule_doc, rule: @rule)
    @rule_doc = @rule.rule_doc
    @rule_doc_committer = Repo::RuleDocCommitter.new([@rule], username: @username)
  end

  it 'commits docs' do
    allow(@rule_doc_committer).to receive(:rules).and_return([@rule])
    expect(@rule_doc_committer).to receive(:call_svn).with("up #{@rule_doc_committer.ruledocs_root}")
    expect(@rule_doc).to receive(:write_to_file)
    expect(@rule_doc_committer).to receive(:call_svn).with("add --force #{@rule_doc_committer.ruledocs_root}")
    expect(@rule_doc_committer).to receive(:call_svn).with(%Q~ci #{@rule_doc_committer.ruledocs_root} -m "#{@username} committed from Analyst Console"~)

    @rule_doc_committer.commit_docs
  end
end
