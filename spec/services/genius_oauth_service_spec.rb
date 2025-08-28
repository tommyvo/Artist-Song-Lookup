require 'rails_helper'

describe GeniusOauthService do
  let(:code) { 'test_code' }
  let(:redirect_uri) { 'http://localhost:3000/callback' }
  let(:client_id) { 'client_id' }
  let(:client_secret) { 'client_secret' }

  before do
    stub_const('ENV', ENV.to_hash.merge(
      'GENIUS_CLIENT_ID' => client_id,
      'GENIUS_CLIENT_SECRET' => client_secret
    ))
  end

  it 'returns token on success' do
    stub_request(:post, 'https://api.genius.com/oauth/token')
      .to_return(status: 200, body: '{"access_token":"abc123"}', headers: { 'Content-Type' => 'application/json' })

    result = described_class.exchange_code_for_token(code, redirect_uri)
    expect(result['access_token']).to eq('abc123')
  end

  it 'returns error on exception' do
    allow(Net::HTTP).to receive(:post_form).and_raise(StandardError.new('fail'))
    result = described_class.exchange_code_for_token(code, redirect_uri)
    expect(result['error']).to eq('An error occurred while connecting to Genius. Please try again later.')
  end
end
