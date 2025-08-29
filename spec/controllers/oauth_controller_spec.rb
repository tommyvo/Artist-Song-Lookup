require 'rails_helper'

describe OauthController, type: :controller do
  describe 'GET #authorize' do
    it 'redirects to the Genius OAuth URL' do
      stub_const('ENV', ENV.to_hash.merge('GENIUS_CLIENT_ID' => 'test_id', 'GENIUS_REDIRECT_URI' => 'http://localhost:3000/callback'))
      get :authorize
      expect(response).to redirect_to(/https:\/\/api\.genius\.com\/oauth\/authorize/)
    end
  end

  describe 'GET #callback' do
    let(:code) { 'test_code' }
    let(:redirect_uri) { 'http://localhost:3000/callback' }

    before do
      stub_const('ENV', ENV.to_hash.merge('GENIUS_REDIRECT_URI' => redirect_uri))
    end

    it 'returns 400 if code param is missing' do
      get :callback
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include('Missing or invalid code parameter')
    end

    it 'stores access token and redirects to root if token is received' do
      allow(GeniusOauthService).to receive(:exchange_code_for_token).and_return({ 'access_token' => 'abc123' })
      get :callback, params: { code: code }
      expect(session[:genius_access_token]).to eq('abc123')
      expect(response).to redirect_to(root_path)
    end

    it 'renders error if token exchange fails' do
      allow(GeniusOauthService).to receive(:exchange_code_for_token).and_return({ 'error' => 'bad_request' })
      get :callback, params: { code: code }
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('OAuth failed')
    end
  end
end
