describe SbApi do
  it "query SDSv3 for 1234computer.com for threat category" do
    threat_category = SbApi.remote_call_sds_v3('1234computer.com','wbrs')
    expect(threat_category).to eq('{"threat_categories":["Malware Sites"]}')
  end

  it "query SDSv2 for google.com for threat levels" do
    threat_levels = SbApi.remote_call_sds('google.com','wbrs')
    expect(threat_levels).to eq('{"response":["Trusted","Good"]}')
  end
end
