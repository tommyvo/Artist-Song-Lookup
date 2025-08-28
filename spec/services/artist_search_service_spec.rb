require 'rails_helper'

describe ArtistSearchService do
  let(:session) { { genius_access_token: 'token' } }
  let(:params) { { q: 'Adele', page: 1, per_page: 10 } }

  it 'returns error if artist name is missing' do
    result = described_class.new({ q: '' }, session).call
    expect(result[:status]).to eq(:bad_request)
    expect(result[:json][:error]).to eq('Missing or invalid artist name')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns error if not authenticated' do
    result = described_class.new(params, {}).call
    expect(result[:status]).to eq(:unauthorized)
    expect(result[:json][:error]).to eq('Not authenticated with Genius')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns error if GeniusApiService returns error' do
    allow(GeniusApiService).to receive(:search_artists).and_return({ 'error' => 'fail' })
    result = described_class.new(params, session).call
    expect(result[:status]).to eq(:bad_gateway)
    expect(result[:json][:error]).to eq('fail')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns paginated results on success' do
    hits = Array.new(15) { |i| { 'result' => { 'id' => i, 'name' => "Artist #{i}" } } }
    allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
    result = described_class.new(params.merge(page: 2, per_page: 10), session).call
    expect(result[:status]).to eq(:ok)
    expect(result[:json][:success]).to eq(true)
    expect(result[:json][:data].size).to eq(5)
    expect(result[:json][:pagination][:page]).to eq(2)
    expect(result[:json][:pagination][:total]).to eq(15)
  end
end
