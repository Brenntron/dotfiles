describe Webcat::EntryVerdictChecker do
  before do
    allow(Wbrs::Category).to receive(:all).and_return(
      [
        Wbrs::Category.new(category_id: 1, mnem: 'edu'),
        Wbrs::Category.new(category_id: 2, mnem: 'art')
      ]
    )
    allow(Webcat::GuardRails).to receive(:verdict_for_entry).and_return(double(body: verdict_response.to_json))
  end

  let(:domain) { 'example.com' }
  let(:categories) { [1, 2] }
  let(:verdict_response) do
    {
      domain => {
        'color' => verdict_color,
        'why' => {
          'reason' => [
            { 'reason' => 'some_reason' }
          ]
        }
      }
    }
  end

  describe 'check' do
    subject { described_class.new(domain, categories).check }

    context 'when GuardRails returns success verdict' do
      let(:verdict_color) { Webcat::GuardRails::PASS }
      let(:expected_result) do
        {
          verdict_pass: true,
          verdict_reasons: []
        }
      end

      it 'returns success result' do
        expect(subject).to eq(expected_result)
      end
    end

    context 'when GuardRails returns unsuccess verdict' do
      let(:verdict_color) { 'ultimate dark red' }

      let(:expected_result) do
        {
          verdict_pass: false,
          verdict_reasons: [
            "|edu = ultimate dark red:some_reason \n",
            "|art = ultimate dark red:some_reason \n"
          ]
        }
      end

      it 'returns unsuccess result' do
        expect(subject).to eq(expected_result)
      end
    end

    context 'when an exception' do
      before do
        allow(Webcat::GuardRails).to receive(:verdict_for_entry).and_raise('Data Temporary Unavailable')
      end

      let(:verdict_color) { Webcat::GuardRails::PASS }
      let(:expected_result) do
        {
          verdict_pass: false,
          verdict_reasons: ['there was an api call failure, erring to manager review']
        }
      end

      it 'returns unsuccess result' do
        expect(subject).to eq(expected_result)
      end
    end
  end
end
