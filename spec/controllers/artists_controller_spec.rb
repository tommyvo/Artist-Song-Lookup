require 'rails_helper'

RSpec.describe Api::V1::ArtistsController, type: :controller do
  describe 'GET #search' do
    let(:artist_name) { 'Kendrick Lamar' }
    let(:artist_id) { 1234 }
    let(:song_titles) { [ 'HUMBLE.', 'DNA.', 'Alright' ] }

    let(:artist_search_service_double) { instance_double(ArtistSearchService) }
    let(:artist_songs_service_double) { instance_double(ArtistSongsService) }

    context 'when the artist is found and songs are returned' do
      before do
        allow(ArtistSearchService).to receive(:new).and_return(artist_search_service_double)
        allow(artist_search_service_double).to receive(:call).and_return({
          json: {
            data: [ { id: artist_id, name: artist_name, primary_artist: { id: artist_id } } ]
          }
        })
        allow(ArtistSongsService).to receive(:new).and_return(artist_songs_service_double)
        allow(artist_songs_service_double).to receive(:call).and_return({
          json: {
            data: song_titles.map { |title| { title: title } },
            pagination: { next_page: nil }
          }
        })
      end

      it 'returns artist name, genius artist id, and a JSON array of song titles' do
        get :search, params: { q: artist_name }
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)['data']
        expect(data['artist_name']).to eq(artist_name.downcase)
        expect(data['genius_artist_id']).to eq(artist_id.to_s)
        expect(data['songs']).to eq(song_titles)
      end
    end

    context 'when the artist is not found' do
      before do
        allow(ArtistSearchService).to receive(:new).and_return(artist_search_service_double)
        allow(artist_search_service_double).to receive(:call).and_return({ json: { data: [] } })
      end

      it 'returns 404 with error message' do
        get :search, params: { q: 'Nonexistent Artist' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Artist not found')
      end
    end
  end
end
