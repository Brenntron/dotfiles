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
  rules.hashes.each do |rule|
    FactoryGirl.create(:rule, rule)
  end
end

Given(/^the following rules exist belonging to bug "(.*?)":$/) do |bug_id, rules|
  bug = Bug.find(bug_id)
  rules.hashes.each do |rule|
    bug.rules << FactoryGirl.create(:rule, rule)
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

Given(/^rule content$/) do
  @gid = 1
  @sid = 25358
  @rev = 4
  @connection = "alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS"
  @message = "APP-DETECT Acunetix web vulnerability scan attempt"
  @detection_parsed = "flowbits:set,acunetix-scan;\ncontent:\"Acunetix-\"; fast_pattern:only; http_header;"
  @detection = @detection_parsed.gsub("\n", ' ')
  @flow = "to_server,established"
  @metadata = "ruleset community, service http"
  @class_type = "web-application-attack"
  @rule_content = "#{@connection} (msg:\"#{@message}\"; flow:#{@flow}; #{@detection} metadata:#{@metadata}; reference:url,www.acunetix.com; classtype:#{@class_type}; sid:#{@sid}; rev:#{@rev};)"
end

Given(/^rule content for following rule:$/) do |rules|
  @rule = FactoryGirl.create(:rule, rules.hashes[0])
  @rule_updated_at = @rule.updated_at
  @gid = @rule.gid
  @sid = @rule.sid
  @rev = @rule.rev
  @connection = @rule.connection
  @message = @rule.message
  @detection_parsed = @rule.detection
  @detection = @detection_parsed.gsub("\n", ' ')
  @flow = @rule.flow
  @metadata = @rule.metadata
  @class_type = @rule.class_type
  @rule_content = "#{@connection} (msg:\"#{@message}\"; flow:#{@flow}; #{@detection} metadata:#{@metadata}; reference:url,www.acunetix.com; classtype:#{@class_type}; sid:#{@sid}; rev:#{@rev};)"
end

Given(/^grep output for rule content$/) do
  @rule_grep_line = "extras/snort/rules/app-detect.rules:33:#{@rule_content}"
end

# Given(/^record exists for rule content$/) do
#   rule = Rule.create!(sid: @sid, rev: @rev, rule_content: @rule_content,
#                       connection: @connection, message: @messages, detection: @detection_parsed,
#                       flow: @flow, metadata: @metadata, class_type: @class_type)
#   @rule_updated_at = rule.updated_at
# end

# Given(/^record with earlier rev exists for rule content$/) do
#   rule = Rule.create!(sid: @sid, rev: (@rev - 1), rule_content: @rule_content,
#                       connection: @connection, message: @messages, detection: @detection_parsed,
#                       flow: @flow, metadata: @metadata, class_type: @class_type)
#   @rule_updated_at = rule.updated_at
# end

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

When(/^code calls load_rule_from_grep on rule content$/) do
  Rule.load_rule_from_grep(@rule_grep_line)
end

Then(/^a rule record for rule conent will exist$/) do
  rule_resultset = Rule.where(sid: @sid)
  rule_resultset.should exist
  rule = rule_resultset.first

  rule.rule_content.should eq(@rule_content)
  rule.sid.should eq(@sid)
  rule.rev.should eq(@rev)
  rule.connection.should eq(@connection)
  rule.message.should eq(@message)
  rule.detection.should eq(@detection_parsed)
  rule.flow.should eq(@flow)
  rule.metadata.should eq(@metadata)
  rule.class_type.should eq(@class_type)
end

Then(/^rule record will be unchanged$/) do
  rule_resultset = Rule.where(sid: @sid)
  rule_resultset.should exist
  rule = rule_resultset.first

  rule.gid.should eq(@gid)
  rule.sid.should eq(@sid)
  rule.updated_at.should eq(@rule_updated_at)
end

Then(/^rule record will be updated$/) do
  rule_resultset = Rule.where(gid: @gid, sid: @sid)
  rule_resultset.should exist
  rule = rule_resultset.first

  rule.gid.should eq(@gid)
  rule.sid.should eq(@sid)
  rule.rev.should eq(@rev)
  rule.updated_at.should_not eq(@rule_updated_at)
end

Then(/^rule record will marked out of date/) do
  rule_resultset = Rule.where(sid: @sid)
  rule_resultset.should exist
  rule = rule_resultset.first

  rule.gid.should eq(@gid)
  rule.sid.should eq(@sid)
  rule.rev.should_not eq(@rev)
  rule.current_edit?.should eq(false)
  rule.stale_edit?.should eq(true)
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
  rule_content = "alert tcp $HOME_NET any -> 64.245.58.0/23 any (msg:\"short msg\"; flow:established; content:\"E_|00 03 05|\"; depth:5; metadata:ruleset community; classtype:misc-activity; sid:#{sid}; rev:#{rev};)"
  Rule.load_rule_from_content(rule_content)
end
