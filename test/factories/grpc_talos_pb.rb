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
    transient do
      rep_rule_id_given {[558]}
    end
    spam_prob_x10000 { 5000 }
    rep_rule_id {Google::Protobuf::RepeatedField.new(:uint32, rep_rule_id_given)}
  end

  factory :grpc_reputation_reply, class: Talos::IPD::ReputationReply do
    transient do
      reputation_given {[[558]]}
    end
    rule_map_version { 890470006 }
    result do
      reputation_local = reputation_given.map do |reputation_hits|
        build(:gprc_ip_results, rep_rule_id_given: reputation_hits)
      end
      Google::Protobuf::RepeatedField.new(:message, Talos::IPD::IPResult, reputation_local)
    end
  end
end
