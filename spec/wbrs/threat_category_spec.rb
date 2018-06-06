describe Wbrs::Category do
  let(:all_cat_json) do
    {
        "data": [
            {
                "category": 4,
                "desc": "a",
                "desc_long": "a",
                "mnem": "a"
            },
            {
                "category": 5,
                "desc": "b",
                "desc_long": "b",
                "mnem": "b"
            },
            {
                "category": 6,
                "desc": "c",
                "desc_long": "c",
                "mnem": "c"
            }
        ]
    }.to_json
  end
  let(:all_cat_response) { double('HTTPI::Response', code: 200, body: all_cat_json) }



  ### TESTS ####################################################################

  it 'should get all the threat categories' do
    expect(Wbrs::Base).to receive(:make_get_request).and_return(all_cat_response)

    categories = Wbrs::ThreatCategory.all

    expect(categories).to be_a_kind_of(Array)
    categories = categories.sort_by{ |cat| cat.id }
    expect(categories.count).to eq(3)
    expect(categories[0].id).to eq(4)
    expect(categories[1].id).to eq(5)
    expect(categories[2].id).to eq(6)
  end

end
