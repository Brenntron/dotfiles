# spec/umbrella/data_fetcher_spec.rb

require 'rails_helper'

RSpec.describe Clusters::DataFetcher, type: :class do
  describe '.fetch' do
    it 'fetches CSV data using Umbrella configuration' do
      allow_any_instance_of(Aws::S3::Client).to receive(:list_objects).and_return(
        double(contents: [double(key: 'umbrella_test.csv')])
      )
      csv_file = File.open("spec/support/umbrella_clusters.csv")

      allow_any_instance_of(Aws::S3::Client).to receive(:get_object).and_return(
        double(body: StringIO.new(csv_file.read))
      )

      csv_data = described_class.fetch

      expect(csv_data).to be_an(Array)
      expect(csv_data.length).to eq(3)
      expect(csv_data.first['cluster_domain']).to eq('peizi00.com')
      expect(csv_data.first['global_volume']).to eq('3549664')
    end
    
    context 'when file is not found in bucket' do
      it 'handles NoSuchKey error gracefully' do
        allow_any_instance_of(Aws::S3::Client).to receive(:list_objects).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, ''))
        
        csv_data = described_class.fetch

        expect(csv_data).to eq([])
      end
    end

    context 'when file is not valid' do
      let(:file) { File.open("spec/support/test.png")}

      it 'handles CSV parsing error gracefully' do
        allow_any_instance_of(Aws::S3::Client).to receive(:list_objects).and_return(
          double(contents: [double(key: 'test.png')])
        )

        allow_any_instance_of(Aws::S3::Client).to receive(:get_object).and_return(
          double(body: StringIO.new(file.read))
        )

        logger = double("logger")
        allow(Rails).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with(/error parsing csv file/)

        csv_data = described_class.fetch

        expect(csv_data).to eq([])
      end
    end
  end
end
