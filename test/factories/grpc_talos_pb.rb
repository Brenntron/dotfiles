require 'service-ipd_services_pb'
require 'service-urs_services_pb'
require 'enrich_pb'

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

  factory :context_tag, class: Talos::ContextTag do
    tag_type_id {1}
    taxonomy_id {1}
    taxonomy_entry_id {1}
  end

  factory :query_reply, class: ::Talos::ENRICH::QueryReply do
    taxonomy_map_version {1}
    context_tags {Google::Protobuf::RepeatedField.new(:message, Talos::ContextTag, [build(:context_tag)])}
  end

  factory :taxonomy_entry, class: Talos::TaxonomyEntry do
    entry_id {1}
    name {Google::Protobuf::RepeatedField.new(:message, Talos::LocalizedString, [build(:localized_string, {text: "entry"})])}
    description {Google::Protobuf::RepeatedField.new(:message, Talos::LocalizedString, [build(:localized_string, {text: "this is a fake entry"})])}
  end

  factory :taxonomy, class: Talos::Taxonomy do
    taxonomy_id {1}
    name {"test taxonomy"}
    description {"this is a fake taxonomy"}
    entries {Google::Protobuf::RepeatedField.new(:message, Talos::TaxonomyEntry, [build(:taxonomy_entry)])}
  end

  factory :taxonomy_map, class: Talos::TaxonomyMap do
    taxonomies {Google::Protobuf::RepeatedField.new(:message, Talos::Taxonomy, [build(:taxonomy)])}
    version {1}
  end

  factory :localized_string, class: Talos::LocalizedString do
    language {"en-us"}
    text {"text"}
  end
end
