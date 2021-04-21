require "rails_helper"

RSpec.describe CloudIntel::ReputationRuleMap do
  context "Normal reputation rule map from network" do
    let (:reputation_rule_map) { FactoryBot.build(:grpc_reputation_rule_map) }
    let (:reputation_rule_map_version) {reputation_rule_map.version}
    let (:first_rep_rule_id) {reputation_rule_map.rules.first.rep_rule_id}
    let (:first_rule_mnemonic) {reputation_rule_map.rules.first.rule_mnemonic}

    it "should return a mnemonic from rep_rule_id" do
      allow_any_instance_of(Talos::Service::IPD::Stub).to receive(:query_rule_map).and_return(reputation_rule_map)

      mnemonic = CloudIntel::ReputationRuleMap.mnemonic(first_rep_rule_id, version: reputation_rule_map_version)

      expect(mnemonic).to eql(first_rule_mnemonic)
    end
  end
end
