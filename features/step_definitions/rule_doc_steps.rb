Given(/^the following rule docs exist:$/) do |docs|
  docs.hashes.each do |doc|
    FactoryBot.create(:rule_doc, doc)
  end
end

Given(/I cannot programatically assign doc "(.*?)" with rule "(.*?)"/) do |doc_id,rule_id|
  doc = RuleDoc.where(id:doc_id).first
  doc.rule_id = rule_id
  !(doc.save)
end