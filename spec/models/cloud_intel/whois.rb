describe CloudIntel::Whois do
  it "passes a test" do
    result = nil

    expect do
      result = CloudIntel::Whois.whois_query('cisco.com')
    end.to_not raise_error

    expect(result.class).to eq(String)
    expect(result.present?).to be_truthy
  end
end
