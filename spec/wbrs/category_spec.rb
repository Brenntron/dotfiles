describe Wbrs::Category do
  let(:all_cat_json) do
    {
        "data": [
            {
                "category": 5,
                "desc_long": "Education-related sites and web pages such as schools, colleges, universities, teaching materials, teachers resources; technical and vocational training; online training; education issues and policies;  financial aid; school funding; standards and testing.",
                "descr": "Education",
                "mnem": "edu"
            },
            {
                "category": 6,
                "desc_long": "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                "descr": "Arts",
                "mnem": "art"
            }
        ]
    }.to_json
  end
  let(:all_cat_response) { double('HTTPI::Response', code: 200, body: all_cat_json) }



  ### TESTS ####################################################################

  it 'should get all the categories' do
    expect(Wbrs::Base).to receive(:call_request).and_return(all_cat_response)

    categories = Wbrs::Category.all.sort_by{ |cat| cat.id }

    expect(categories.count).to eql(2)
    expect(categories[0].id).to eql(5)
    expect(categories[1].id).to eql(6)
  end

end
