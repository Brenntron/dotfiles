describe ComplaintEntryPreload do

  let(:complaint_entry) do
    new_complaint_entry = ComplaintEntry.new
    new_complaint_entry.complaint_id = Complaint.first.id
    new_complaint_entry.user_id = 1
    new_complaint_entry.uri = "www.test.com"
    new_complaint_entry.entry_type = "URI/DOMAIN"
    new_complaint_entry.wbrs_score = nil
    new_complaint_entry.suggested_disposition = "Search Engines and Portals"
    new_complaint_entry.url_primary_category = "Search Engines and Portals"
    new_complaint_entry.subdomain = "www"
    new_complaint_entry.domain = "test.com"
    new_complaint_entry.path = nil
    new_complaint_entry.status = ComplaintEntry::NEW
    new_complaint_entry.is_important = 0
    new_complaint_entry.save

    return new_complaint_entry
  end

  before(:example) do
    FactoryBot.create(:complaint)
  end

  it 'preloads complaint entry data' do
    test_entry = complaint_entry
    preload = ComplaintEntryPreload.generate_preload_from_complaint_entry(test_entry) # note that we do not load json into this; it accepts a ComplaintEntry
    expect(preload).to eq(true)
    expect(ComplaintEntry.first.complaint_id).to eq(Complaint.first.id)
  end

end
