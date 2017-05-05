Given (/^a "(.*?)" rule exists$/) do |rule|
  @rule = FactoryGirl.create(:rule)
end

Given(/^a rule exists and belongs to bug "(.*?)"/)  do |bug_id|
  rule = FactoryGirl.create(:rule)
  Bug.find(bug_id).rules << rule
end

Given(/^"(.*?)" rules exist and belong to bug "(.*?)"/)  do |number, bug_id|
  number.to_i.times do
    rule = FactoryGirl.create(:rule)
    Bug.find(bug_id).rules << rule
  end
end

Given(/^bug with id "(.*)" has rule with id "(.*)"$/) do |bug_id, rule_id|
  Bug.find(bug_id).rules << Rule.find(rule_id)
end

Given(/^the following rules exist:$/) do |rules|
  rules.hashes.each do |rule_attrs|
    FactoryGirl.create(:rule, rule_attrs)
  end
end

Given(/^the following rules exist belonging to bug "(.*?)":$/) do |bug_id, rules|
  bug = Bug.find(bug_id)
  rules.hashes.each do |rule_attrs|
    bug.rules << FactoryGirl.create(:rule, rule_attrs)
  end
end

Then(/^I click the "(.*?)" tab$/) do |value|
  tab = "#{value}".downcase
  find(:xpath, "//ul[@id='bug_tab']/li/a[@data-target='##{tab}-tab']").click()
end

Then(/^"(.*?)" should be listed first$/) do |value|
  find_field('rule_category_id').all('option').collect(&:text)[1].should == value
end


Then(/^test should be created and I should see "(.*?)"$/) do |content|
  raise "Content not found. Make sure AMQ and background jobs are running." unless page.has_content?(content)
end

Then(/^I toggle "(.*?)"$/) do |content|
  page.find(:xpath, "//div[@class='#{content}']").click()
end

Given(/^record "(.*)" updated to:$/) do |rule_id, rules|
  rule = Rule.find(rule_id)
  rule.update!(rules.hashes[0])
end

Given(/^rule content rev set to "(.*)"$/) do |rev|
  @rev = rev.to_i
  @rule_content = "#{@connection} (msg:\"#{@message}\"; flow:#{@flow}; #{@detection} metadata:#{@metadata}; reference:url,www.acunetix.com; classtype:#{@class_type}; sid:#{@sid}; rev:#{@rev};)"
end

Given(/^rule with id "(.*)" has a reference with id "(.*)"$/) do |rule_id, ref_id|
  @rule = Rule.find(rule_id)
  @rule.references << Reference.find(ref_id)
end

When(/^code calls load_grep on "(.*)"/) do |rule_grep_line|
  Rule.load_grep(rule_grep_line)
end

When(/^code calls revert_grep for rule gid "(.*)" sid "(.*)" on "(.*)"/) do |gid, sid, rule_grep_line|
  rule = Rule.by_sid(sid, gid).first
  rule.revert_grep(rule_grep_line)
end

When(/^code calls revert_rules_action for rule gid "(.*)" sid "(.*)"$/) do |gid, sid|
  rule = Rule.by_sid(sid, gid).first
  Rule.revert_rules_action([rule.id])
end

Then (/^a rule record for rule gid "(.*)" sid "(.*)" will exist$/) do |gid, sid|
  rule_resultset = Rule.by_sid(sid, gid)
  rule_resultset.should exist
  rule = rule_resultset.first
end

Then(/^I should see a rule with state "(.*)" version "(.*)"$/) do |state, version|
  page.find(:xpath, "//td[text()='#{state}']")
  page.find(:xpath, "//td//*[normalize-space(text())='#{version}']")
end

Then(/^I should see rule "(.*)" state "(.*)" version "(.*)"$/) do |rule_id, state, version|
  page.find(:xpath, "//tr[@id='#{rule_id}']/td[text()='#{state}']")
  page.find(:xpath, "//tr[@id='#{rule_id}']//*[normalize-space(text())='#{version}']")
end

Then(/^I should see the bug rules table$/) do
  page.find(:xpath, "//table[@id='bug-rules-table']")
end

Then(/^I should see a rule row with id "(.*)"$/) do |rule_id|
  page.find(:xpath, "//table[@id='bug-rules-table']//tr[@id='#{rule_id}']")
end

Then(/^A rule gid "(.*)" and sid "(.*)" has rev "(.*)"$/) do |gid, sid, rev|
  rule = Rule.by_sid(sid, gid).first
  rule && (rule.rev.should == rev.to_i)
end

Then(/^A rule gid "(.*)" and sid "(.*)" has class "(.*)"$/) do |gid, sid, css_class|
  rule = Rule.by_sid(sid, gid).first
  rule && rule.css_class.split(' ').should(include(css_class))
end

Then(/^I should see a rule row with class "(.*)" and id "(.*)"$/) do |css_class, rule_id|
  page.find(:xpath, "//table[@id='bug-rules-table']//tr[@id='#{rule_id}']")[:class].split(' ').should include(css_class)
end

Then(/^I should see a rule row with class "(.*)" and version "(.*)"$/) do |css_class, version|
  page.find(:xpath, "//table[@id='bug-rules-table']//tr[.//*[normalize-space(text())='#{version}']]")[:class].split(' ').should include(css_class)
end

Then(/^rule "(.*)" is synched$/) do |rule_id|
  rule = Rule.find(rule_id)
  rule.synched?.should == true
  rule.draft?.should == false
end

Then(/^rule "(.*)" is a current edit/) do |rule_id|
  rule = Rule.find(rule_id)
  rule.synched?.should == false
  rule.draft?.should == true
  rule.new_rule?.should == false
  rule.edited_rule?.should == true
  rule.current_edit?.should == true
end

Given(/^rule sid "(.*)" rev "(.*)" is synched$/) do |sid, rev|
  rule_content = %Q~alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:#{sid}; rev:#{rev};)~
  Rule.synch_rule_content(rule_content)
end

Then(/^a rule gid "(\d*)" and sid "(\d*)" should be on$/) do |gid, sid|
  rule = Rule.by_sid(sid, gid).first
  rule.should_be_on?.should == true
end

Then(/^a rule gid "(\d*)" and sid "(\d*)" should be off$/) do |gid, sid|
  rule = Rule.by_sid(sid, gid).first
  rule.should_be_on?.should == false
end

Then(/^a rule gid "(\d*)" and sid "(\d*)" is on$/) do |gid, sid|
  rule = Rule.by_sid(sid, gid).first
  rule.rule_content_for_commit.should_not match(/^\s*#/)
end

Then(/^a rule gid "(\d*)" and sid "(\d*)" is off/) do |gid, sid|
  rule = Rule.by_sid(sid, gid).first
  rule.rule_content_for_commit.should match(/^\s*#/)
end
