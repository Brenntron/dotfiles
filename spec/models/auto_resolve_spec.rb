describe AutoResolve do
  describe 'checking sources' do
    let(:auto_cisco) { AutoResolve.new(address_type: 'URI/DOMAIN', address: 'cisco.com', rule_hits: []) }
    let(:virus_total_clear_json) {
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
      }.to_json
    }
    let(:virus_total_clear_response) { double('HTTPI::Response', code: 200, body: virus_total_clear_json) }
    let(:virus_total_400_response) { double('HTTPI::Response', code: 400, body: virus_total_clear_json) }
    let(:virus_total_202_response) { double('HTTPI::Response', code: 202, body: virus_total_clear_json) }
    let(:virus_total_conviction_json) {
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
      }.to_json
    }
    let(:virus_total_conviction_response) { double('HTTPI::Response', code: 200, body: virus_total_conviction_json) }
    let(:umbrella_clear_json) {
      {
          "cisco.com" => {
              "status" => 1,
              "security_categories" => [],
              "content_categories" => ["25","32"]
          }
      }.to_json
    }
    let(:umbrella_clear_response) { double('HTTPI::Response', code: 200, body: umbrella_clear_json) }
    let(:umbrella_400_response) { double('HTTPI::Response', code: 400, body: umbrella_clear_json) }
    let(:umbrella_202_response) { double('HTTPI::Response', code: 202, body: umbrella_clear_json) }
    let(:umbrella_conviction_json) {
      {
          "cisco.com" => {
              "status" => -1,
              "security_categories" => [],
              "content_categories" => ["25","32"]
          }
      }.to_json
    }
    let(:umbrella_conviction_response) { double('HTTPI::Response', code: 200, body: umbrella_conviction_json) }

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
      expect(HTTPI).to receive(:get).and_return(virus_total_clear_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to include('VT: -;')
    end

    it 'populates virus total convicted internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(HTTPI).to receive(:get).and_return(virus_total_conviction_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_truthy
      expect(auto_cisco.internal_comment).to include('Kaspersky: kaspermalicious;')
    end

    it 'handles virus total http error code' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(HTTPI).to receive(:get).and_return(virus_total_400_response)

      expect {
        auto_cisco.check_sources(rule_hits: [])
      }.to raise_error(Virustotal::VirustotalError)

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to be_blank
    end

    it 'handles virus total http error code' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(HTTPI).to receive(:get).and_return(virus_total_202_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to include('VT: -;')
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
      expect(HTTPI).to receive(:post).and_return(umbrella_clear_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to include('Umbrella: -;')
    end

    it 'populates umbrella convicted internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(HTTPI).to receive(:post).and_return(umbrella_conviction_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_truthy
      expect(auto_cisco.internal_comment).to include('Umbrella: malicious domain.')
    end

    it 'populates umbrella clear internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(HTTPI).to receive(:post).and_return(umbrella_400_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to be_blank
    end

    it 'populates umbrella clear internal comment' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(HTTPI).to receive(:post).and_return(umbrella_202_response)

      auto_cisco.check_sources(rule_hits: [])

      expect(auto_cisco.malicious?).to be_falsey
      expect(auto_cisco.internal_comment).to include('Umbrella: -;')
    end
  end
end
