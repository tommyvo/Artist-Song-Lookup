require 'rails_helper'

describe OauthCallbackService do
  let(:session) { {} }
  let(:params) { { code: 'test_code' } }
  let(:redirect_uri) { 'http://localhost:3000/callback' }

  before do
    stub_const('ENV', ENV.to_hash.merge('GENIUS_REDIRECT_URI' => redirect_uri))
  end

  it 'returns error if code is missing' do
    result = described_class.new({ code: '' }, session).call
    expect(result[:status]).to eq(:bad_request)
    expect(result[:body]).to eq('Missing or invalid code parameter')
  end

  it 'stores access token and returns success if token is received' do
    allow(GeniusOauthService).to receive(:exchange_code_for_token).and_return({ 'access_token' => 'abc123' })
    result = described_class.new(params, session).call
  expect(result[:status]).to eq(200)
    expect(result[:body]).to include('OAuth successful')
    expect(session[:genius_access_token]).to eq('abc123')
  end

  it 'returns error if token exchange fails' do
    allow(GeniusOauthService).to receive(:exchange_code_for_token).and_return({ 'error' => 'fail' })
    result = described_class.new(params, session).call
    expect(result[:status]).to eq(:unauthorized)
    expect(result[:body]).to include('OAuth failed: fail')
  end
end
