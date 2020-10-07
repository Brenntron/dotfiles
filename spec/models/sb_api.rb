describe SbApi do
  it "query SDSv3 for 1234computer.com for threat category" do
    threat_category = SbApi.remote_call_sds_v3('1234computer.com','wbrs')
    expect(threat_category).to eq("{\"categories\":[{\"short_description\":\"Illegal Activities\",\"long_description\":\"Promoting crime, such as stealing, fraud, illegally accessing telephone networks; computer viruses; terrorism, bombs, and anarchy; websites depicting murder and suicide as well as explaining ways to commit them.\"}],\"threat_categories\":[\"Malware Sites\"]}")
  end

  it "query SDSv2 for google.com for threat levels" do
    threat_levels = SbApi.remote_call_sds('google.com','wbrs')
    expect(threat_levels).to eq("{\"response\":[\"Favorable\",\"Good\"]}")
  end
end
