FactoryBot.define do
  factory :alert do
    test_group      { "pcap" }
    rule_id         { 1 }
    attachment_id   { 1 }
  end
end
