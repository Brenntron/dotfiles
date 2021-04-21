require "rails_helper"

RSpec.describe CloudIntel::ReputationRuleMap do
  it "should return a mnemonic from id" do
    allow_any_instance_of(Talos::Service::IPD::Stub).to receive(:query_rule_map)
                                                            .and_return(FactoryBot.build(:grpc_reputation_rule_map))

    mnemonic = CloudIntel::ReputationRuleMap.mnemonic(558, version: 890470006)

    expect(mnemonic).to eql('Pbl')
  end
end
