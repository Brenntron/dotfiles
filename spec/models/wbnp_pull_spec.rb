describe 'wbnp pull' do

  before(:each) do
    Complaint.destroy_all
    ComplaintEntry.destroy_all
  end

  after(:each) do

  end

  it "should reject invalid urls (1)" do

    bad_url_package_1 = {
        "data" => [
            {"add_channel"=>"wbnp", "comment"=>"", "complaint_id"=>3672399, "complaint_type"=>"unknown", "customer_name"=>"LOWE'S COMPANIES INC", "description"=>"", "domain"=>"http.com", "path"=>"//intranet2.lowes.com/store_comms_nonauth/automated_filters/upload/payablesus_wk49_132020_1101172.asp", "port"=>0, "protocol"=>"http", "region"=>"", "resolution"=>nil, "state"=>"new", "subdomain"=>"www", "tag"=>"invalid", "url_query_string"=>"authToken=eMjUzNi0xMjE1MTAwOTktMTc2NDYyMjI3LTY5MjQ4NTgzNC1fMF9rbmxsb3dlc18zX180XyVjMGM5ODYwMy1jNDhmLTRhMzctYTBmNS02MmQxNjY2MWRkMzk", "when_added"=>"Fri, 10 Jan 2020 15:10:02 GMT", "when_last_updated"=>"Fri, 10 Jan 2020 15:10:02 GMT", "who_updated"=>""}
        ]
    }


    expect(Wbrs::RuleUiComplaint).to receive(:where).with({:add_channels => [Complaint::WBNP_CHANNEL], :statuses => ['new']}).and_return(bad_url_package_1).at_least(:once)
    expect(Wbrs::RuleUiComplaint).to receive(:tag_complaint).and_return("Complaint's tag was updated successfully.").at_least(:once)
    expect(Wbrs::RuleUiComplaint).to receive(:assign_tickets).and_return({"already_assigned"=>[], "assigned"=>[3672399], "not_found"=>[]})
    logger_token = SecureRandom.uuid
    new_report = WbnpReport.new
    new_report.notes = ""
    new_report.cases_imported = 0
    new_report.cases_failed = 0
    new_report.total_new_cases = 1
    new_report.status = WbnpReport::ACTIVE
    new_report.notes += "logger_token: #{logger_token} <br />"
    new_report.save

    Complaint.start_wbnp_pull(new_report.id, logger_token)
    new_report.reload

    expect(new_report.cases_failed).to eql(1)
    expect(Complaint.all.size).to eql(0)
    expect(ComplaintEntry.all.size).to eql(0)
  end

  it "should reject invalid urls (2)" do
    #"http://ad.doubleclick.net/clk;259531881;73739211;o;pc=[tpas_id]"
    #

    bad_url_package_2 = {
        "data" => [
            {"add_channel"=>"wbnp", "comment"=>"", "complaint_id"=>3672399, "complaint_type"=>"unknown", "customer_name"=>"LOWE'S COMPANIES INC", "description"=>"", "domain"=>"doubleclick.net", "path"=>"clk;259531881;73739211;o;pc=[tpas_id]", "port"=>0, "protocol"=>"http", "region"=>"", "resolution"=>nil, "state"=>"new", "subdomain"=>"ad", "tag"=>"invalid", "url_query_string"=>"", "when_added"=>"Fri, 10 Jan 2020 15:10:02 GMT", "when_last_updated"=>"Fri, 10 Jan 2020 15:10:02 GMT", "who_updated"=>""}
        ]
    }


    expect(Wbrs::RuleUiComplaint).to receive(:where).with({:add_channels => [Complaint::WBNP_CHANNEL], :statuses => ['new']}).and_return(bad_url_package_2).at_least(:once)
    expect(Wbrs::RuleUiComplaint).to receive(:tag_complaint).and_return("Complaint's tag was updated successfully.").at_least(:once)
    expect(Wbrs::RuleUiComplaint).to receive(:assign_tickets).and_return({"already_assigned"=>[], "assigned"=>[3672399], "not_found"=>[]})
    logger_token = SecureRandom.uuid
    new_report = WbnpReport.new
    new_report.notes = ""
    new_report.cases_imported = 0
    new_report.cases_failed = 0
    new_report.total_new_cases = 1
    new_report.status = WbnpReport::ACTIVE
    new_report.notes += "logger_token: #{logger_token} <br />"
    new_report.save

    Complaint.start_wbnp_pull(new_report.id, logger_token)
    new_report.reload

    expect(new_report.cases_failed).to eql(1)
    expect(Complaint.all.size).to eql(0)
    expect(ComplaintEntry.all.size).to eql(0)

  end

  it "should reject invalid urls (3)" do
    #pokerstars.eu)

    bad_url_package_2 = {
        "data" => [
            {"add_channel"=>"wbnp", "comment"=>"", "complaint_id"=>3672399, "complaint_type"=>"unknown", "customer_name"=>"LOWE'S COMPANIES INC", "description"=>"", "domain"=>"pokerstars.eu)", "path"=>"", "port"=>0, "protocol"=>"http", "region"=>"", "resolution"=>nil, "state"=>"new", "subdomain"=>"", "tag"=>"invalid", "url_query_string"=>"", "when_added"=>"Fri, 10 Jan 2020 15:10:02 GMT", "when_last_updated"=>"Fri, 10 Jan 2020 15:10:02 GMT", "who_updated"=>""}
        ]
    }


    expect(Wbrs::RuleUiComplaint).to receive(:where).with({:add_channels => [Complaint::WBNP_CHANNEL], :statuses => ['new']}).and_return(bad_url_package_2).at_least(:once)
    expect(Wbrs::RuleUiComplaint).to receive(:tag_complaint).and_return("Complaint's tag was updated successfully.").at_least(:once)
    expect(Wbrs::RuleUiComplaint).to receive(:assign_tickets).and_return({"already_assigned"=>[], "assigned"=>[3672399], "not_found"=>[]})
    logger_token = SecureRandom.uuid
    new_report = WbnpReport.new
    new_report.notes = ""
    new_report.cases_imported = 0
    new_report.cases_failed = 0
    new_report.total_new_cases = 1
    new_report.status = WbnpReport::ACTIVE
    new_report.notes += "logger_token: #{logger_token} <br />"
    new_report.save

    Complaint.start_wbnp_pull(new_report.id, logger_token)
    new_report.reload

    expect(new_report.cases_failed).to eql(1)
    expect(Complaint.all.size).to eql(0)
    expect(ComplaintEntry.all.size).to eql(0)

  end

  it "should create new complaint and complaint entry for valid urls" do

    good_url_package_1 = {
        "data" => [
            {"add_channel"=>"wbnp", "comment"=>"", "complaint_id"=>3672399, "complaint_type"=>"unknown", "customer_name"=>"LOWE'S COMPANIES INC", "description"=>"", "domain"=>"doubleclick.net", "path"=>"", "port"=>0, "protocol"=>"http", "region"=>"", "resolution"=>nil, "state"=>"new", "subdomain"=>"www", "tag"=>"invalid", "url_query_string"=>"", "when_added"=>"Fri, 10 Jan 2020 15:10:02 GMT", "when_last_updated"=>"Fri, 10 Jan 2020 15:10:02 GMT", "who_updated"=>""}
        ]
    }

    expect(Wbrs::RuleUiComplaint).to receive(:where).with({:add_channels => [Complaint::WBNP_CHANNEL], :statuses => ['new']}).and_return(good_url_package_1).at_least(:once)

    expect(Wbrs::RuleUiComplaint).to receive(:assign_tickets).and_return({"already_assigned"=>[], "assigned"=>[3672399], "not_found"=>[]})

    logger_token = SecureRandom.uuid
    new_report = WbnpReport.new
    new_report.notes = ""
    new_report.cases_imported = 0
    new_report.cases_failed = 0
    new_report.total_new_cases = 1
    new_report.status = WbnpReport::ACTIVE
    new_report.notes += "logger_token: #{logger_token} <br />"
    new_report.save

    Complaint.start_wbnp_pull(new_report.id, logger_token)
    new_report.reload
    expect(new_report.cases_imported).to eql(1)
    expect(Complaint.all.size).to eql(1)
    expect(ComplaintEntry.all.size).to eql(1)
  end

end