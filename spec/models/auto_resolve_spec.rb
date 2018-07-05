describe Repo::RuleCommitter do
  describe 'checking sources' do
    let(:auto_cisco) { AutoResolve.new(address_type: 'URI/DOMAIN', address: 'cisco.com', rule_hits: []) }

    it 'checks complaints' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to receive(:check_complaints)

      auto_cisco.check_sources(rule_hits: [])

    end

    it 'skips complaints' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to_not receive(:check_complaints)

      auto_cisco.check_sources(rule_hits: [])

    end

    it 'checks virus total' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to receive(:check_virus_total)

      auto_cisco.check_sources(rule_hits: [])

    end

    it 'skips virus total' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to_not receive(:check_virus_total)

      auto_cisco.check_sources(rule_hits: [])

    end

    it 'checks umbrella' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(auto_cisco).to receive(:check_umbrella)

      auto_cisco.check_sources(rule_hits: [])

    end

    it 'skips umbrella' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to_not receive(:check_umbrella)

      auto_cisco.check_sources(rule_hits: [])

    end
  end

  it 'clears cisco.com' do

    auto = AutoResolve.create_from_payload(address_type: 'URI/DOMAIN', address: 'cisco.com')

    expect(auto.new?).to be_truthy
  end
end
