require 'rails_helper'

describe Api::V1::ArtistsController, type: :controller do
  describe 'GET #search' do
    it 'returns 401 if not authenticated' do
      get :search, params: { q: 'Adele' }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
      expect(json['data']).to eq([])
      expect(json['error']).to eq('Not authenticated with Genius')
      expect(json['pagination']).to eq({})
    end

    it 'returns 400 if artist name is missing' do
      get :search
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
      expect(json['data']).to eq([])
      expect(json['error']).to eq('Missing or invalid artist name')
      expect(json['pagination']).to eq({})
    end

    it 'returns empty results for now if artist name is present' do
  session[:genius_access_token] = 'fake_token'
  allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [] } })
  allow(RedisClient).to receive(:get).and_return(nil)
  get :search, params: { q: 'Adele' }
  json = JSON.parse(response.body)
  expect(json['success']).to eq(true)
  expect(json['data']).to eq([])
  expect(json['error']).to be_nil
  expect(json['pagination']).to include('page', 'per_page', 'total', 'total_pages')
    end

    it 'returns 502 if Genius API returns an error' do
      session[:genius_access_token] = 'fake_token'
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'error' => 'timeout' })
      allow(RedisClient).to receive(:get).and_return(nil)
      get :search, params: { q: 'Adele' }
      expect(response).to have_http_status(:bad_gateway)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
      expect(json['data']).to eq([])
      expect(json['error']).to eq('timeout')
      expect(json['pagination']).to eq({})
    end

    it 'handles pagination metadata correctly' do
      session[:genius_access_token] = 'fake_token'
      hits = Array.new(15) { |i| { 'result' => { 'id' => i, 'name' => "Artist \\#{i}" } } }
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
      get :search, params: { q: 'Adele', page: 2, per_page: 10 }
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      expect(json['data'].size).to eq(5)
      expect(json['pagination']['page']).to eq(2)
      expect(json['pagination']['per_page']).to eq(10)
      expect(json['pagination']['total']).to eq(15)
      expect(json['pagination']['total_pages']).to eq(2)
      expect(json['error']).to be_nil
    end

    it 'handles empty results from Genius API' do
      session[:genius_access_token] = 'fake_token'
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [] } })
      get :search, params: { q: 'Unknown Artist' }
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      expect(json['data']).to eq([])
      expect(json['pagination']['total']).to eq(0)
      expect(json['error']).to be_nil
    end

    it 'handles malformed Genius API response gracefully' do
  session[:genius_access_token] = 'fake_token'
  # Simulate a malformed response (no 'hits' key)
  allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => {} })
  allow(RedisClient).to receive(:get).and_return(nil)
  get :search, params: { q: 'Adele' }
  json = JSON.parse(response.body)
  expect(json['success']).to eq(true)
  expect(json['data']).to eq([])
  expect(json['pagination']['total']).to eq(0)
  expect(json['error']).to be_nil
    end

    it 'handles invalid page and per_page params' do
      session[:genius_access_token] = 'fake_token'
      hits = Array.new(5) { |i| { 'result' => { 'id' => i, 'name' => "Artist \\#{i}" } } }
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
      allow(RedisClient).to receive(:get).and_return(nil)
      get :search, params: { q: 'Adele', page: -1, per_page: 'abc' }
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      expect(json['data'].size).to eq(5)
      expect(json['pagination']['page']).to eq(1)
      expect(json['error']).to be_nil
    end
  end
  describe 'GET #songs' do
    let(:access_token) { 'token' }
    let(:session_data) { { genius_access_token: access_token } }
    let(:artist_id) { '123' }
    let(:params) { { genius_artist_id: artist_id } }

    before do
      allow(controller).to receive(:session).and_return(session_data)
    end

    it 'returns 401 if not authenticated' do
      allow(controller).to receive(:session).and_return({})
      get :songs, params: params
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
      expect(json['error']).to eq('Not authenticated with Genius')
    end

    it 'returns 400 if genius_artist_id is missing' do
      get :songs, params: { genius_artist_id: '' }
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
      expect(json['error']).to eq('Missing or invalid genius_artist_id')
    end

    it 'returns 502 if Genius API returns an error' do
      allow(ArtistSongsService).to receive(:new).and_return(double(call: { status: :bad_gateway, json: { success: false, data: [], error: 'fail', pagination: {} } }))
      get :songs, params: params
      expect(response).to have_http_status(:bad_gateway)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(false)
      expect(json['error']).to eq('fail')
    end

    it 'returns songs on success' do
      songs = [ { 'id' => 1, 'title' => 'Song 1' } ]
      service_result = {
        status: :ok,
        json: {
          success: true,
          data: songs,
          error: nil,
          pagination: { page: 1, per_page: 10, total: 1, next_page: nil }
        }
      }
      allow(ArtistSongsService).to receive(:new).and_return(double(call: service_result))
      get :songs, params: params
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      expect(json['data']).to eq(songs)
      expect(json['pagination']['page']).to eq(1)
    end
  end
end
