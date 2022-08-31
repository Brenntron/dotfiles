require "rails_helper"

RSpec.describe EnrichmentService::QueryInterface do
  let (:enrich_stub) {Talos::Service::ENRICH::Stub.new('nosuchaddress.com:9000', :this_channel_is_insecure)}
  let (:tts_stub) {Talos::Service::TTS::Stub.new('nosuchaddress.com:9000', :this_channel_is_insecure)}
  context "Enrich query" do
    let (:taxonomy_map) do
      FactoryBot.build(:taxonomy_map)
    end

    let(:query_reply) do
      FactoryBot.build(:query_reply)
    end

    let(:taxonomy_map) do
      FactoryBot.build(:taxonomy_map)
    end

    it "query domain" do
      Rails.cache.clear
      allow(EnrichmentService::Enrich).to receive(:remote_stub).and_return(enrich_stub)
      allow(EnrichmentService::Tts).to receive(:remote_stub).and_return(tts_stub)
      allow(enrich_stub).to receive(:query_domain).and_return(query_reply)
      allow(tts_stub).to receive(:query_taxonomy_map).and_return(taxonomy_map)

      response = EnrichmentService::QueryInterface.domain_query("test.com")

      expect(Rails.cache.read("taxonomy_map")).to_not eq(nil)
      expect(Rails.cache.read("taxonomy_map_version")).to eq(1)
      expect(response["context_tags"][0]["mapped_taxonomy"]["name"][0]["text"]).to eq("entry")
    end
  end
end