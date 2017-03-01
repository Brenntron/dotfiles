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

Given(/^rule conent$/) do
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

Given(/^grep output for rule content$/) do
  @rule_grep_line = "extras/snort/rules/app-detect.rules:33:#{@rule_content}"
end

Given(/^record exists for rule content$/) do
  rule = Rule.create!(sid: @sid, rev: @rev, rule_content: @rule_content,
                      connection: @connection, message: @messages, detection: @detection_parsed,
                      flow: @flow, metadata: @metadata, class_type: @class_type)
  @rule_updated_at = rule.updated_at
end

Given(/^record with earlier rev exists for rule content$/) do
  rule = Rule.create!(sid: @sid, rev: (@rev - 1), rule_content: @rule_content,
                      connection: @connection, message: @messages, detection: @detection_parsed,
                      flow: @flow, metadata: @metadata, class_type: @class_type)
  @rule_updated_at = rule.updated_at
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

  rule.sid.should eq(@sid)
  rule.rev.should eq(@rev)
  rule.updated_at.should eq(@rule_updated_at)
end

Then(/^rule record will be updated$/) do
  rule_resultset = Rule.where(sid: @sid)
  rule_resultset.should exist
  rule = rule_resultset.first

  rule.sid.should eq(@sid)
  rule.rev.should eq(@rev)
  rule.updated_at.should_not eq(@rule_updated_at)
end

Then(/^I should see rule "(.*)" state "(.*)" version "(.*)"$/) do |rule_id, state, version|
  page.find(:xpath, "//tr[@id='#{rule_id}']/td[text()='#{state}']")
  page.find(:xpath, "//tr[@id='#{rule_id}']/td/a/strong[text()='#{version}']")
end

