FactoryGirl.define do
  factory :bug do
    sequence :bugzilla_id do |nn|
      111000 + nn
    end
    state 'OPEN'
    summary 'Summary for testing'
    product 'Research'
    component 'Snort Rules'
    version '2.5.2'
    description 'Description for testing'
  end
end
