describe AutoResolve do
  describe 'checking sources' do
    # Test Cases
    # 1.  Complaints has at least one hit, VT and Umbrella convict, produces NEW ticket.
    # 2.  Complaints has at least one hit, VT and Umbrella acquit, produces NEW ticket.
    # 3.  Complaints has no hits, VT convicts, Umbrella acquits, produces malicious status.
    # 4.  Complaints has no hits, VT acquits, Umbrella convicts, produces malicious status.
    # 5.  Complaints has no hits, VT acquits, Umbrella acquits, produces non-malicious status.
    # 6.  Complaints has no hits, VT acquits, Umbrella check disabled produces NEW ticket.
    # 7.  Complaints has no hits, VT acquits, Umbrella check fails to connect produces NEW ticket.
    # 8.  Complaints has no hits, VT check disabled, Umbrella convicts, produces malicious status.
    # 9.  Complaints has no hits, VT check fails to connect, Umbrella convicts, produces malicious status.
    # 10. Complaints has no hits, VT check disabled, Umbrella acquits, produces NEW ticket.
    # 11. Complaints has no hits, VT check fails to connect, Umbrella acquits, produces NEW ticket.
    # 12. Complaints has no hits, VT check disabled, Umbrella check disabled produces NEW ticket.
    # 13. Complaints has no hits, VT check disabled, Umbrella check fails to connect produces NEW ticket.
    # 14. Complaints has no hits, VT check fails to connect, Umbrella check disabled produces NEW ticket.
    # 15. Complaints has no hits, VT check fails to connect, Umbrella check fails to connect produces NEW ticket.


    let(:target_address) {'192.230.66.19'}
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
          target_address => {
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
          target_address => {
              "status" => -1,
              "security_categories" => [],
              "content_categories" => ["25","32"]
          }
      }.to_json
    }
    let(:umbrella_conviction_response) { double('HTTPI::Response', code: 200, body: umbrella_conviction_json) }


    it 'skips complaints' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(false)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(auto_cisco).to_not receive(:check_complaints)
      expect(auto_cisco).to_not receive(:check_virus_total)
      expect(auto_cisco).to_not receive(:check_umbrella)

      auto_cisco.check_sources(rule_hits: [])

    end

    # 1.  Complaints has at least one hit, VT and Umbrella convict, produces NEW ticket.
    it 'produces new ticket when complaints hits and VT and Umbrella convict' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, %w{alx_cln vsvd})

      expect(auto_resolve.resolved?).to be_falsey
      expect(auto_resolve.internal_comment).to include('Kaspersky: kaspermalicious;')
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 2.  Complaints has at least one hit, VT and Umbrella acquit, produces NEW ticket.
    it 'produces new ticket when complaints hits and VT and Umbrella aquit' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_clear_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_clear_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, %w{alx_cln vsvd})

      expect(auto_resolve.resolved?).to be_falsey
      expect(auto_resolve.internal_comment).to include('VT: -;')
      expect(auto_resolve.internal_comment).to include('Umbrella: -;')
    end

    # 3.  Complaints has no hits, VT convicts, Umbrella acquits, produces malicious status.
    it 'resolves as malicious when Complaints has no hits, VT convicts, Umbrella acquits' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_clear_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Kaspersky: kaspermalicious;')
      expect(auto_resolve.internal_comment).to include('Umbrella: -;')
    end

    # 4.  Complaints has no hits, VT acquits, Umbrella convicts, produces malicious status.
    it 'resolves as malicious when Complaints has no hits, VT acquits, Umbrella convicts' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_clear_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('VT: -;')
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 5.  Complaints has no hits, VT acquits, Umbrella acquits, produces non-malicious status.
    it 'resolves as non-malicious when Complaints has no hits, VT acquits, Umbrella acquits' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_clear_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_clear_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_falsey
      expect(auto_resolve.internal_comment).to include('VT: -;')
      expect(auto_resolve.internal_comment).to include('Umbrella: -;')
    end

    # 6.  Complaints has no hits, VT acquits, Umbrella check disabled produces NEW ticket.
    it 'produces new ticket when Complaints has no hits, VT acquits, Umbrella check disabled' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_clear_json))
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_falsey
      expect(auto_resolve.internal_comment).to include('VT: -;')
    end

    # 7.  Complaints has no hits, VT acquits, Umbrella check fails to connect produces NEW ticket.
    it 'produces new ticket when Complaints has no hits, VT acquits, Umbrella check disabled' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_clear_json))
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_falsey
      expect(auto_resolve.internal_comment).to include('VT: -;')
    end

    # 8.  Complaints has no hits, VT check disabled, Umbrella convicts, produces malicious status.
    it 'resolves as malicious when Complaints has no hits, VT is disabled, Umbrella convicts' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 9.  Complaints has no hits, VT check fails to connect, Umbrella convicts, produces malicious status.
    it 'resolves as malicious when Complaints has no hits, VT is disabled, Umbrella convicts' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 10. Complaints has no hits, VT check disabled, Umbrella acquits, produces NEW ticket.
    it 'resolves as malicious when Complaints has no hits, VT is disabled, Umbrella convicts' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 11. Complaints has no hits, VT check fails to connect, Umbrella acquits, produces NEW ticket.
    it 'resolves as malicious when Complaints has no hits, VT is disabled, Umbrella convicts' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(true)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
    end

    # 12. Complaints has no hits, VT check disabled, Umbrella check disabled produces NEW ticket.
    it 'produces new ticket when Complaints has no hits and VT and Umbrella convict' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(false)
      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_falsey
    end

    # 13. Complaints has no hits, VT check disabled, Umbrella check fails to connect produces NEW ticket.
    it 'produces new ticket when Complaints has no hits and VT and Umbrella convict' do
      allow(Rails.configuration.complaints).to receive(:check).and_return(true)
      allow(Rails.configuration.virus_total).to receive(:check).and_return(false)
      allow(Rails.configuration.umbrella).to receive(:check).and_return(true)
      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [])

      expect(auto_resolve.resolved?).to be_falsey
    end

    # 14. Complaints has no hits, VT check fails to connect, Umbrella check disabled produces NEW ticket.
    # 15. Complaints has no hits, VT check fails to connect, Umbrella check fails to connect produces NEW ticket.

  end
end
