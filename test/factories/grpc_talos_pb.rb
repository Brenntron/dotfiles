require 'service-ipd_services_pb'

FactoryBot.define do
  factory :grpc_reputation_rule_map, class: Talos::ReputationRuleMap do
    rules {Google::Protobuf::RepeatedField.new(:message, Talos::ReputationRule,
                                               [build(:grpc_reputation_rule, {rep_rule_id: 558, rule_mnemonic: 'Pbl'}),
                                                build(:grpc_reputation_rule, {rep_rule_id: 564, rule_mnemonic: 'Smd'}),
                                                build(:grpc_reputation_rule, {rep_rule_id: 579, rule_mnemonic: 'Ce2'}),
                                                build(:grpc_reputation_rule, {rep_rule_id: 625, rule_mnemonic: 'TrN'})])}
    version         { 890470006 }
  end

  factory :grpc_reputation_rule, class: Talos::ReputationRule do
    rep_rule_id     { 558 }
    rule_mnemonic   { 'Pbl' }
  end
end
