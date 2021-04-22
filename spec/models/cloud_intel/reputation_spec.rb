require "rails_helper"

RSpec.describe CloudIntel::Reputation do
  let (:ipd_stub) {Talos::Service::IPD::Stub.new('nosuchaddress.com:9000', :this_channel_is_insecure)}

  context "Normal reputation reply" do
    let (:reputation_reply) do
      FactoryBot.build(:grpc_reputation_reply, reputation_given: [[558, 564], [579]])
    end

    it "gets reputation hits" do
      Rails.cache.clear
      allow(Beaker::Ipd).to receive(:remote_stub).and_return(ipd_stub)
      allow(ipd_stub).to receive(:query_reputation).and_return(reputation_reply)

      reputations = CloudIntel::Reputation.reputation_ips(["2.3.4.5", "35.236.52.109"])

      expect(reputations["2.3.4.5"][:reputation].rep_rule_ids).to eql([558, 564])
      expect(reputations["35.236.52.109"][:reputation].rep_rule_ids).to eql([579])
    end
  end
end
