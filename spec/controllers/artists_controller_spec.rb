require 'rails_helper'

describe ArtistsController, type: :controller do
  describe 'GET #search' do
    it 'returns 401 if not authenticated' do
      get :search, params: { q: 'Adele' }
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('Not authenticated with Genius')
    end

    it 'returns 400 if artist name is missing' do
      get :search
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to eq('Missing artist name')
    end

    it 'returns empty results for now if artist name is present' do
      session[:genius_access_token] = 'fake_token'
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [] } })
      get :search, params: { q: 'Adele' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['artists']).to eq([])
      expect(json['pagination']).to include('page', 'per_page', 'total')
    end

    it 'returns 502 if Genius API returns an error' do
      session[:genius_access_token] = 'fake_token'
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'error' => 'timeout' })
      get :search, params: { q: 'Adele' }
      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)['error']).to eq('timeout')
    end

    it 'handles pagination metadata correctly' do
      session[:genius_access_token] = 'fake_token'
      hits = Array.new(15) { |i| { 'result' => { 'id' => i, 'name' => "Artist #{i}" } } }
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
      get :search, params: { q: 'Adele', page: 2, per_page: 10 }
      json = JSON.parse(response.body)
      expect(json['artists'].size).to eq(5)
      expect(json['pagination']['page']).to eq(2)
      expect(json['pagination']['per_page']).to eq(10)
      expect(json['pagination']['total']).to eq(15)
      expect(json['pagination']['total_pages']).to eq(2)
    end

    it 'handles empty results from Genius API' do
      session[:genius_access_token] = 'fake_token'
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [] } })
      get :search, params: { q: 'Unknown Artist' }
      json = JSON.parse(response.body)
      expect(json['artists']).to eq([])
      expect(json['pagination']['total']).to eq(0)
    end

    it 'handles malformed Genius API response gracefully' do
      session[:genius_access_token] = 'fake_token'
      allow(GeniusApiService).to receive(:search_artists).and_return({})
      get :search, params: { q: 'Adele' }
      json = JSON.parse(response.body)
      expect(json['artists']).to eq([])
      expect(json['pagination']['total']).to eq(0)
    end

    it 'handles invalid page and per_page params' do
      session[:genius_access_token] = 'fake_token'
      hits = Array.new(5) { |i| { 'result' => { 'id' => i, 'name' => "Artist #{i}" } } }
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
      get :search, params: { q: 'Adele', page: -1, per_page: 'abc' }
      json = JSON.parse(response.body)
      expect(json['artists'].size).to eq(5)
      expect(json['pagination']['page']).to eq(1)
    end
  end
end
