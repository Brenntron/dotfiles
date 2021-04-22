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

    let (:reputation_reply) do
      FactoryBot.build(:grpc_reputation_reply, reputation_given: [[558, 564], [579]])
    end

    let (:ipd_stub) {Talos::Service::IPD::Stub.new('nosuchaddress.com:9000', :this_channel_is_insecure)}

    #     reply = Beaker::Ipd.query_reputation(ips)

    let (:input_ips) { ["2.3.4.5", "35.236.52.109"] }

    it "gets reputation hits" do
      Rails.cache.clear
      allow(Beaker::Ipd).to receive(:remote_stub).and_return(ipd_stub)
      allow(ipd_stub).to receive(:query_rule_map).and_return(reputation_rule_map)
      allow(ipd_stub).to receive(:query_reputation).and_return(reputation_reply)

      reputations = CloudIntel::Reputation.reputation_ips(["2.3.4.5", "35.236.52.109"])

      expect(reputations["2.3.4.5"][:reputation].rep_rule_ids).to eql([558, 564])
      expect(reputations["35.236.52.109"][:reputation].rep_rule_ids).to eql([579])
    end
  end
end
