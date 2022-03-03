Given(/^the following Secure Endpoint Naming Conventions exist:$/) do |convention|
  convention.hashes.each do |convention_attrs|
    FactoryBot.create(:amp_naming_convention, convention_attrs)
  end
end
