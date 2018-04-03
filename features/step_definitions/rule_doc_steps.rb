Given(/^the following rule docs exist:$/) do |docs|
  docs.hashes.each do |doc|
    FactoryGirl.create(:rule_doc, doc)
  end
end