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
  @classtype = "web-application-attack"
  @rule_content = "#{@connection} (msg:\"#{@message}\"; flow:#{@flow}; #{@detection} metadata:#{@metadata}; reference:url,www.acunetix.com; classtype:#{@classtype}; sid:#{@sid}; rev:#{@rev};)"
end

Given(/grep output for rule content/) do
  @rule_grep_line = "extras/snort/rules/app-detect.rules:33:#{@rule_content}"
end

When(/^code calls load_rule_from_grep on rule content/) do
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
  rule.class_type.should eq(@classtype)
end

