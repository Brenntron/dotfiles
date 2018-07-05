describe Repo::RuleCommitter do
  describe 'checking sources' do
    let(:auto_cisco) { AutoResolve.new(address_type: 'URI/DOMAIN', address: 'cisco.com', rule_hits: []) }
    let(:virus_total_clear_parsed) {
      {
          "scans" => {
              "zvelo" => {
                  "detected" => false,
                  "result" => "clean site"
              },
              "Kaspersky" => {
                  "detected" => false,
                  "result" => "clean site"
              },
              "Sophos" => {
                  "detected" => false,
                  "result" => "unrated site"
              }
          }
      }
    }
    let(:virus_total_conviction_parsed) {
      {
          "scans" => {
              "zvelo" => {
                  "detected" => false,
                  "result" => "clean site"
              },
              "Kaspersky" => {
                  "detected" => true,
                  "result" => "kaspermalicious"
              },
              "Sophos" => {
                  "detected" => false,
                  "result" => "unrated site"
              }
          }
      }
    }
    let(:umbrella_clear_parsed) {
      {
          "cisco.com" => {
              "status" => 1,
              "security_categories" => [],
              "content_categories" => ["25","32"]
          }
      }
    }
    let(:umbrella_conviction_parsed) {
      {
          "cisco.com" => {
              "status" => -1,
              "security_categories" => [],
              "content_categories" => ["25","32"]
          }
      }
    }

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

    it 'populates virus total clear internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to receive(:call_virus_total).and_return(virus_total_clear_parsed)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to include('VT: -;')
    end

    it 'populates virus total convicted internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to receive(:call_virus_total).and_return(virus_total_conviction_parsed)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_truthy
      expect(auto_cisco.internal_comment).to include('Kaspersky: kaspermalicious;')
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

    it 'populates umbrella clear internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(auto_cisco).to receive(:call_umbrella).and_return(umbrella_clear_parsed)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to include('Umbrella: -;')
    end

    it 'populates umbrella convicted internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(auto_cisco).to receive(:call_umbrella).and_return(umbrella_conviction_parsed)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_truthy
      expect(auto_cisco.internal_comment).to include('Umbrella: malicious domain.')
    end
  end

  it 'clears cisco.com' do

    auto = AutoResolve.create_from_payload(address_type: 'URI/DOMAIN', address: 'cisco.com')

    expect(auto.new?).to be_truthy
    expect(auto.domain?).to be_truthy
  end

  it 'clears http://www.cisco.com' do

    auto = AutoResolve.create_from_payload(address_type: 'URI/DOMAIN', address: 'http://www.cisco.com')

    expect(auto.new?).to be_truthy
    expect(auto.uri?).to be_truthy
  end

  it 'clears 72.163.4.161' do

    auto = AutoResolve.create_from_payload(address_type: 'IP', address: '72.163.4.161')

    expect(auto.new?).to be_truthy
    expect(auto.ip?).to be_truthy
  end
end
