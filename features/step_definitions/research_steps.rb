Then(/^two research entries exists$/) do
  expect( all('.research-table-row').count ).to eq(2)
end

Then(/^multiple research entry exists$/) do
  expect( all('.research-table-row').count ).to be > (1)
end