require 'service-ipd_services_pb'
require 'service-urs_services_pb'

FactoryBot.define do
  factory :grpc_reputation_rule, class: Talos::ReputationRule do
    rep_rule_id     { 558 }
    rule_mnemonic   { 'Pbl' }
  end

  factory :grpc_reputation_rule_map, class: Talos::ReputationRuleMap do
    rules do
      Google::Protobuf::RepeatedField.new(:message, Talos::ReputationRule,
                                          [build(:grpc_reputation_rule, {rep_rule_id: 558, rule_mnemonic: 'Pbl'}),
                                           build(:grpc_reputation_rule, {rep_rule_id: 564, rule_mnemonic: 'Smd'}),
                                           build(:grpc_reputation_rule, {rep_rule_id: 579, rule_mnemonic: 'Ce2'}),
                                           build(:grpc_reputation_rule, {rep_rule_id: 625, rule_mnemonic: 'TrN'})])
    end
    version         { 890470006 }
  end

  factory :gprc_ip_results, class: Talos::IPD::IPResult do
    spam_prob_x10000 { 5000 }
    rep_rule_id {Google::Protobuf::RepeatedField.new(:uint32, [558])}
  end

  factory :grpc_reputation_reply, class: Talos::IPD::ReputationReply do
  # factory :grpc_reputation_reply, class: Talos.IPD.IPResult do
    rule_map_version { 890470006 }
    result do
      Google::Protobuf::RepeatedField.new(:message, Talos::IPD::IPResult,
                                          [ build(:gprc_ip_results) ])

    end
  end
end

# reply.result.first.rep_rule_id.first.class
# => Integer

