describe K2::Base do
  describe '.request' do
    it 'sets right headers' do
      expected_headers = {
        "Authorization"=>"Bearer 1.0 redached",
        "Content-type"=>"application/json"
      }
      expect(described_class.request.headers).to eq(expected_headers)
    end

    it 'skip verify SSL' do
      expect(described_class.ssl?). to eq(false)
    end
  end


  describe '.request_error_handling' do
    let(:response) { HTTPI::Response.new(rand(300..500), {}, '') }
    context 'when response failed' do
      before do
        allow(response).to receive(:error?).and_return(true)
      end

      it 'calls handle_error_response  method' do
        expect(described_class).to receive(:handle_error_response).with(response)
        described_class.request_error_handling(response)
      end
    end

    context 'when response is successfull' do
      let(:body) {  "\"some_string\"" }
      let(:code) { rand(200..299)}

      before do
        response.code = code
        response.body = body
      end

      it 'does not call .handle_error_response method' do
        expect(described_class).not_to receive(:handle_error_response)
        described_class.request_error_handling(response)
      end

      it 'returns accurate response' do
        result = described_class.request_error_handling(response)
        expect(result.class).to eq(described_class::Response)
        expect(result.code).to eq(code)
        expect(result.body).to eq('some_string')
      end
    end
  end

  describe 'handle_error_response' do
    context 'when response is nil' do
      it 'sets default error message' do
        expect(described_class.handle_error_response.error).to eq(described_class::DEFAULT_ERROR_MESSAGE)
      end

      it 'returns response with code nil' do
        expect(described_class.handle_error_response.code).to eq(nil)
      end
    end

    context 'when response is not nil' do
      let(:response) { HTTPI::Response.new(rand(300..500), {}, '') }
      let(:code) { rand(200..500)}

      before do
        response.code = code
      end

      it 'sets error message' do
        expect(described_class.handle_error_response(response).error).to eq("HTTP response #{code}. #{described_class::DEFAULT_ERROR_MESSAGE}")
      end

      it 'returns response with code' do
        expect(described_class.handle_error_response(response).code).to eq(code)
      end
    end
  end
end
