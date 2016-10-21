FactoryGirl.define do
  factory :bug do
    bugzilla_id '111111'
    state 'OPEN'
    summary 'Summary for testing'
    product 'Research'
    component 'Snort Rules'
    version '2.5.2'
    description 'Description for testing'
  end
end