Then(/^one research entry exists$/) do
  expect( all('.research-table-row').count ).to eq(1)
end

Then(/^multiple research entry exists$/) do
  expect( all('.research-table-row').count ).to be > (1)
end