describe AutoResolve do
  describe 'live API calls' do
    it 'clears cisco.com' do

      auto = AutoResolve.create_from_payload('URI/DOMAIN', 'cisco.com')

      expect(auto.new?).to be_truthy
      expect(auto.domain?).to be_truthy
    end

    it 'clears http://www.cisco.com' do

      auto = AutoResolve.create_from_payload('URI/DOMAIN', 'http://www.cisco.com')

      expect(auto.new?).to be_truthy
      expect(auto.uri?).to be_truthy
    end

    it 'clears 72.163.4.161' do

      auto = AutoResolve.create_from_payload('IP', '72.163.4.161')

      expect(auto.new?).to be_truthy
      expect(auto.ip?).to be_truthy
    end
  end
end
