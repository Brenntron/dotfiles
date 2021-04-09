describe ComplaintEntry do
  context 'complaint entry credit changes' do
    before do
      allow(ComplaintEntryCredits::CreditProcessor).to receive(:new).and_return(double(process: true))
      allow(Wbrs::Prefix).to receive(:where).and_return([wbrs_prefix])
    end

    let(:credit_processor) { ComplaintEntryCredits::CreditProcessor.new(user, complaint_entry) }
    let(:wbrs_prefix) do
      Wbrs::Prefix.new_from_attributes(
        category_id: 27,
        domain: "example.com",
        is_active: 1,
        path: "",
        port: 0,
        prefix_id: 1236119,
        protocol: "http",
        subdomain: "",
        truncated: 0
      )
    end

    describe 'change_category' do
      subject(:change_category) do
        complaint_entry.change_category(prefix,
                                        categories_string,
                                        category_names_string,
                                        entry_status,
                                        comment,
                                        resolution_comment,
                                        uri_as_categorized,
                                        current_user,
                                        commit_pending)
      end

      before do
        allow(Wbrs::Prefix).to receive(:where).and_return([wbrs_prefix])
        allow(Wbrs::Prefix).to receive(:new).and_return(double(set_categories: 123)) # some id
      end

      let(:user) { FactoryBot.create(:user) }
      let(:prefix) { 'example.com' }
      let(:categories_string) { '27' }
      let(:category_names_string) { 'Advertisements' }
      let(:entry_status) { 'FIXED' }
      let(:comment) { 'comment' }
      let(:resolution_comment) { 'resolution comment' }
      let(:uri_as_categorized) { 'example.com' }
      let(:current_user) { user }
      let(:commit_pending) { '' }
      let(:complaint_entry) { FactoryBot.create(:complaint_entry) }

      it 'requests ComplaintEntryCredits::CreditProcessor' do
        expect(credit_processor).to receive(:process)
        change_category
      end
    end

    describe 'create_complaint_entry' do
      subject(:create_complaint_entry) do
        described_class.create_complaint_entry(complaint, ip_url, user)
      end

      before do
        allow(Sbrs::ManualSbrs).to receive(:get_wbrs_data).and_return({"wbrs"=>{"score"=>4.9}, "wbrs-rulehits"=>[28]})
        allow(Wbrs::TopUrl).to receive(:check_urls).and_return(double(is_important: true))
        allow(ComplaintEntryPreload).to receive(:generate_preload_from_complaint_entry).and_return(true)
      end

      let(:complaint) { FactoryBot.create(:complaint) }
      let(:ip_url) { 'example.com' }
      let(:user) { FactoryBot.create(:user) }

      it 'requests ComplaintEntryCredits::CreditProcessor' do
        expect(ComplaintEntryCredits::CreditProcessor).to receive_message_chain(:new, :process)
        create_complaint_entry
      end
    end
  end
end
