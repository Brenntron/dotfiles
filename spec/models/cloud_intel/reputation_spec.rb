require "rails_helper"

RSpec.describe CloudIntel::Reputation do
  # example:
  #   Reputation.reputation_ips(["2.3.4.5", "35.236.52.109"])
  #   => { "2.3.4.5" => {reputation: Reputation},
  #        "35.236.52.109" => {reputation: Reputation}
  #
  #               {
  #                   ip: ip,
  #                   mnemonics: reputation.mnemonics,
  #                   spam_percent: reputation.spam_percent
  #               }

  context "always a context" do
    let (:reputation_rule_map) { FactoryBot.build(:grpc_reputation_rule_map) }
    let (:reputation_rule_map_version) {reputation_rule_map.version}
    # let (:first_rep_rule_id) {reputation_rule_map.rules.first.rep_rule_id}
    # let (:first_rule_mnemonic) {reputation_rule_map.rules.first.rule_mnemonic}
    # Talos::IPD::ReputationReply

    let (:reputation_reply) { FactoryBot.build(:grpc_reputation_reply) }

    let (:ipd_stub) {Talos::Service::IPD::Stub.new('nosuchaddress.com:9000', :this_channel_is_insecure)}

    #     reply = Beaker::Ipd.query_reputation(ips)

    let (:input_ips) { ["2.3.4.5", "35.236.52.109"] }

    it "gets reputation hits" do
      Rails.cache.clear
      allow(Beaker::Ipd).to receive(:remote_stub).and_return(ipd_stub)
      allow(ipd_stub).to receive(:query_rule_map).and_return(reputation_rule_map)
      byebug
      allow(ipd_stub).to receive(:query_reputation).and_return(reputation_reply)

      reputations = Reputation.reputation_ips(["2.3.4.5", "35.236.52.109"])

      reputation = reputations["2.3.4.5"][:reputation]
      reputation = reputations["35.236.52.109"][:reputation]
    end
  end
end
