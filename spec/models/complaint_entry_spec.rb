describe ComplaintEntry do
  context 'complaint entry credit changes' do
    before do
      allow(WebcatCredits::ComplaintEntries::CreditProcessor).to receive(:new).and_return(double(process: true))
      allow(Wbrs::Prefix).to receive(:where).and_return([wbrs_prefix])
    end

    let(:credit_processor) { WebcatCredits::ComplaintEntries::CreditProcessor.new(user, complaint_entry) }
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
                                        commit_pending,
                                        false)
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

      it 'requests WebcatCredits::ComplaintEntries::CreditProcessor' do
        expect(credit_processor).to receive(:process)
        change_category
      end

      xit 'should change category with abuse category to extreme' do
        #can't test this because pushing to test wbrs doesn't seem to acknowledge new categories
        expect(credit_processor).to receive(:process)

        complaint_entry.change_category('examplething.com',
                                        '64',
                                        'Child Abuse Content',
                                        'FIXED',
                                        'comment',
                                        'resolution comment',
                                        'example.com',
                                        user,
                                        '',
                                        false)

        expect(complaint_entry.url_primary_category).to eql("Extreme")

        #change_category
      end

      it 'should not pass guardrails and return without categorizing' do
        puts Wbrs::Category.all
        expect(credit_processor).to receive(:process)
        complaint_entry.status = "PENDING"
        complaint_entry.is_important = true
        complaint_entry.save
        complaint_entry.change_category('google.com',
                                        '27',
                                        'Advertisements',
                                        'FIXED',
                                        'comment',
                                        'resolution comment',
                                        'google.com',
                                        user,
                                        'commit',
                                        false)

        expect(complaint_entry.status).to eql("yeah")
      end

      it 'should categorize if if self-review is set to true' do

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

      xit 'requests WebcatCredits::ComplaintEntries::CreditProcessor' do
        expect(WebcatCredits::ComplaintEntries::CreditProcessor).to receive_message_chain(:new, :process)
        create_complaint_entry
      end
    end

    describe 'process_resolution_changes' do
      subject(:process_resolution_changes) do
        described_class.process_resolution_changes(resolution, internal_comment, customer_facing_comment, user)

        let(:resolution) { "UNCHANGED" }
        let(:internal_comment) { "we do not want to categorize this" }
        let(:customer_facing_comment) { "all good!" }

        xit 'requests ComplaintEntryCredits::CreditProcessor' do
          expect(ComplaintEntryCredits::CreditProcessor).to receive_message_chain(:new, :process)
          create_complaint_entry
        end
      end
    end

  end
end
