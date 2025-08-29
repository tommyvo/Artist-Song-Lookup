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
    allow(RedisClient).to receive(:get).and_return(nil)
    allow(GeniusApiService).to receive(:search_artists).and_return({ 'error' => 'fail' })
    result = described_class.new(params, session).call
    expect(result[:status]).to eq(:bad_gateway)
    expect(result[:json][:error]).to eq('fail')
    expect(result[:json][:success]).to eq(false)
  end

  it 'retries and returns custom error on timeout' do
    allow(RedisClient).to receive(:get).and_return(nil)
    call_count = 0

    allow(GeniusApiService).to receive(:search_artists) do
      call_count += 1
      { 'error' => 'timeout' }
    end

    result = described_class.new(params, session).call
    expect(call_count).to eq(3)
    expect(result[:status]).to eq(:bad_gateway)
    expect(result[:json][:error]).to match(/Genius API error: Timeout::Error/)
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns paginated results on success' do
    hits = Array.new(15) { |i| { 'result' => { id: i, name: "Artist #{i}" } } }
    allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
    result = described_class.new(params.merge(page: 2, per_page: 10), session).call
    expect(result[:status]).to eq(:ok)
    expect(result[:json][:success]).to eq(true)
    expect(result[:json][:data].size).to eq(5)
    expect(result[:json][:pagination][:page]).to eq(2)
    expect(result[:json][:pagination][:total]).to eq(15)
  end

  describe 'caching' do
    let(:params) { { q: 'Adele', page: 1, per_page: 10 } }
    let(:session) { { genius_access_token: 'token' } }
    let(:cache_key) { "artist_search:adele:page=1:per_page=10" }
    let(:cached_result) do
      {
        status: :ok,
        json: {
          success: true,
          data: [ { id: 1, name: 'Adele' } ],
          error: nil,
          pagination: { page: 1, per_page: 10, total: 1, total_pages: 1 }
        }
      }
    end


    it 'writes to cache on cache miss for successful lookup' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(nil)
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [ { 'result' => { id: 1, name: 'Adele' } } ] } })
      expect(RedisClient).to receive(:set).with(cache_key, anything, hash_including(:ex))
      described_class.new(params, session).call
    end

    it 'does not write to cache if GeniusApiService returns error' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(nil)
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'error' => 'fail' })
      expect(RedisClient).not_to receive(:set)
      described_class.new(params, session).call
    end

    it 'does not write to cache if GeniusApiService returns no hits' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(nil)
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [] } })
      expect(RedisClient).not_to receive(:set)
      described_class.new(params, session).call
    end

    it 'returns cached result on cache hit and skips API call' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(cached_result.to_json)
      expect(GeniusApiService).not_to receive(:search_artists)
      result = described_class.new(params, session).call
      expect(result).to eq(cached_result.deep_symbolize_keys)
    end
  end
end

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
    allow(RedisClient).to receive(:get).and_return(nil)
    allow(GeniusApiService).to receive(:search_artists).and_return({ 'error' => 'fail' })
    result = described_class.new(params, session).call
    expect(result[:status]).to eq(:bad_gateway)
    expect(result[:json][:error]).to eq('fail')
    expect(result[:json][:success]).to eq(false)
  end

  it 'returns paginated results on success' do
    hits = Array.new(15) { |i| { 'result' => { id: i, name: "Artist #{i}" } } }
    allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => hits } })
    result = described_class.new(params.merge(page: 2, per_page: 10), session).call
    expect(result[:status]).to eq(:ok)
    expect(result[:json][:success]).to eq(true)
    expect(result[:json][:data].size).to eq(5)
    expect(result[:json][:pagination][:page]).to eq(2)
    expect(result[:json][:pagination][:total]).to eq(15)
  end

  describe 'caching' do
    let(:params) { { q: 'Adele', page: 1, per_page: 10 } }
    let(:session) { { genius_access_token: 'token' } }
    let(:cache_key) { "artist_search:adele:page=1:per_page=10" }
    let(:cached_result) do
      {
        status: :ok,
        json: {
          success: true,
          data: [ { id: 1, name: 'Adele' } ],
          error: nil,
          pagination: { page: 1, per_page: 10, total: 1, total_pages: 1 }
        }
      }
    end

    it 'writes to cache on cache miss' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(nil)
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [ { 'result' => { id: 1, name: 'Adele' } } ] } })
      expect(RedisClient).to receive(:set).with(cache_key, anything, hash_including(:ex))
      described_class.new(params, session).call
    end

    it 'returns cached result on cache hit and skips API call' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(cached_result.to_json)
      expect(GeniusApiService).not_to receive(:search_artists)
      result = described_class.new(params, session).call
      expect(result).to eq(cached_result.deep_symbolize_keys)
    end
  end

  describe 'caching' do
    let(:params) { { q: 'Adele', page: 1, per_page: 10 } }
    let(:session) { { genius_access_token: 'token' } }
    let(:cache_key) { "artist_search:adele:page=1:per_page=10" }
    let(:cached_result) do
      {
        status: :ok,
        json: {
          success: true,
          data: [ { 'id' => 1, 'name' => 'Adele' } ],
          error: nil,
          pagination: { page: 1, per_page: 10, total: 1, total_pages: 1 }
        }
      }
    end

    it 'writes to cache on cache miss' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(nil)
      allow(GeniusApiService).to receive(:search_artists).and_return({ 'response' => { 'hits' => [ { 'result' => { 'id' => 1, 'name' => 'Adele' } } ] } })
      expect(RedisClient).to receive(:set).with(cache_key, anything, hash_including(:ex))
      described_class.new(params, session).call
    end

    it 'returns cached result on cache hit and skips API call' do
      allow(RedisClient).to receive(:get).with(cache_key).and_return(cached_result.to_json)
      expect(GeniusApiService).not_to receive(:search_artists)
      result = described_class.new(params, session).call
      expect(result).to eq(cached_result.deep_symbolize_keys)
    end
  end
end
