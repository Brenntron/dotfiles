FactoryBot.define do
  factory :dispute_rule_hit do
    name { 'dotq' }
    dispute_entry_id { 1 }
    rule_type { 'WBRS' }
  end
end
