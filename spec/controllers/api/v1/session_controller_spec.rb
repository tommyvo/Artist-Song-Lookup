require 'rails_helper'

RSpec.describe Api::V1::SessionController, type: :controller do
  describe 'GET #show' do
    context 'when genius_access_token is present in session' do
      before { session[:genius_access_token] = 'abc123' }

      it 'returns authenticated: true' do
        get :show
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'authenticated' => true })
      end
    end

    context 'when genius_access_token is not present in session' do
      it 'returns authenticated: false and 401' do
        get :show
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ 'authenticated' => false })
      end
    end
  end
end
