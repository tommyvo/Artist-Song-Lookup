require 'rails_helper'

describe GeniusApiService do
  let(:access_token) { 'fake_token' }
  let(:query) { 'Adele' }

  describe '.search_artists' do
    it 'returns parsed JSON on success' do
      stub_request(:get, /api\.genius\.com\/search/)
        .with(headers: { 'Authorization' => "Bearer #{access_token}" })
        .to_return(status: 200, body: '{"response":{"hits":[{"result":{"id":1,"name":"Adele"}}]}}', headers: { 'Content-Type' => 'application/json' })

      result = described_class.search_artists(query, access_token)
      expect(result['response']['hits'].first['result']['name']).to eq('Adele')
    end

    it 'returns error on timeout' do
      allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      result = described_class.search_artists(query, access_token)
      expect(result['error']).to eq('The request to Genius timed out. Please try again later.')
    end

    it 'returns error on other exceptions' do
      allow(Net::HTTP).to receive(:start).and_raise(StandardError.new('fail'))
      result = described_class.search_artists(query, access_token)
      expect(result['error']).to eq('An unexpected error occurred while contacting Genius. Please try again later.')
    end
  end
end
