Given(/^the following notes exist:$/) do |notes|
  notes.hashes.each do |note|
    FactoryBot.create(:note, note)
  end
end

Then (/^note number "(.*?)" should say "(.*?)"$/) do |number, text|
  page.should have_selector("#list_history div.research-note:nth-child(#{number}) .comment",text: text)
end

