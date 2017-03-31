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

    factory :open_bug do
      # Yes this is currently the default, but a factory specifically making an open bug.
      state 'OPEN'
    end
  end
end
