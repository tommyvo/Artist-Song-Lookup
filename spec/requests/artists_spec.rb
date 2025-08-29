require 'rails_helper'

RSpec.describe 'Artists API', type: :request do
  # Enable Rails exception handling so rescue_from and rescue blocks are triggered in request specs
  before do
    allow(Rails.application.env_config).to receive(:[]).and_call_original
    allow(Rails.application.env_config).to receive(:[]).with('action_dispatch.show_exceptions').and_return(true)
    allow(Rails.application.env_config).to receive(:[]).with('action_dispatch.show_detailed_exceptions').and_return(false)
  end

  describe 'GET /api/v1/artists/search' do
    let(:artist_name) { 'Kendrick Lamar' }
    let(:artist_id) { 1234 }
    let(:song_titles) { [ 'HUMBLE.', 'DNA.', 'Alright' ] }

    before do
      allow(ArtistSearchService).to receive(:new).and_call_original
      allow(ArtistSongsService).to receive(:new).and_call_original
    end

    context 'when the artist is found and songs are returned' do
      before do
        artist_search_double = instance_double(ArtistSearchService)
        allow(ArtistSearchService).to receive(:new).and_return(artist_search_double)
        allow(artist_search_double).to receive(:call).and_return({
          json: {
            data: [ { id: artist_id, name: artist_name, primary_artist: { id: artist_id } } ]
          }
        })

        artist_songs_double = instance_double(ArtistSongsService)
        allow(ArtistSongsService).to receive(:new).and_return(artist_songs_double)
        allow(artist_songs_double).to receive(:call).and_return({
          json: {
            data: song_titles.map { |title| { title: title } },
            pagination: { next_page: nil }
          }
        })
      end

      it 'returns a JSON array of song titles' do
        get '/api/v1/artists/search', params: { q: artist_name }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(song_titles)
      end
    end

    context 'when the artist is not found' do
      before do
        artist_search_double = instance_double(ArtistSearchService)
        allow(ArtistSearchService).to receive(:new).and_return(artist_search_double)
        allow(artist_search_double).to receive(:call).and_return({ json: { data: [] } })
      end

      it 'returns 404 with error message' do
        get '/api/v1/artists/search', params: { q: 'Nonexistent Artist' }
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Artist not found')
      end
    end
  end
end
