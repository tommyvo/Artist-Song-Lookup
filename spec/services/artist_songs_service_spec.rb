require 'rails_helper'

describe ArtistSongsService do
  let(:session) { { genius_access_token: 'token' } }
  let(:params) { { genius_artist_id: '123', page: 1, per_page: 10 } }

  it 'returns error if genius_artist_id is missing' do
    result = described_class.new({ genius_artist_id: '' }, session).call
    expect(result[:status]).to eq(:bad_request)
    expect(result[:json][:error]).to eq('Missing or invalid genius_artist_id')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns error if not authenticated' do
    result = described_class.new(params, {}).call
    expect(result[:status]).to eq(:unauthorized)
    expect(result[:json][:error]).to eq('Not authenticated with Genius')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns error if GeniusApiService returns error' do
    allow(GeniusApiService).to receive(:fetch_artist_songs).and_return({ 'error' => 'fail' })
    result = described_class.new(params, session).call
    expect(result[:status]).to eq(:bad_gateway)
    expect(result[:json][:error]).to eq('fail')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns songs on success' do
    songs = [ { 'id' => 1, 'title' => 'Song 1' }, { 'id' => 2, 'title' => 'Song 2' } ]
    allow(GeniusApiService).to receive(:fetch_artist_songs).and_return({ 'response' => { 'songs' => songs, 'next_page' => nil } })
    result = described_class.new(params, session).call
    expect(result[:status]).to eq(:ok)
    expect(result[:json][:success]).to eq(true)
    expect(result[:json][:data]).to eq(songs)
    expect(result[:json][:pagination][:page]).to eq(1)
    expect(result[:json][:pagination][:total]).to eq(2)
    expect(result[:json][:error]).to be_nil
  end

  it 'handles Genius API pagination' do
    allow(GeniusApiService).to receive(:fetch_artist_songs).and_return({ 'response' => { 'songs' => [], 'next_page' => 2 } })
    result = described_class.new(params, session).call
    expect(result[:json][:pagination][:next_page]).to eq(2)
  end
end
