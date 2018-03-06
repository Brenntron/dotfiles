Given(/^the following giblets exist:$/) do |giblets|
  giblets.hashes.each do |giblet|
    FactoryGirl.create(:giblet, giblet)
  end
end