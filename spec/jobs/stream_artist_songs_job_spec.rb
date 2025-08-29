require 'rails_helper'
require 'action_cable/engine'

RSpec.describe StreamArtistSongsJob, type: :job do
  let(:search_id) { 'testsearch123' }
  let(:artist_id) { 42 }
  let(:session_data) { { user_id: 1 } }

  let(:service_double) { double('ArtistSongsService') }

  before do
    allow(ArtistSongsService).to receive(:new).and_return(service_double)
    allow(ActionCable.server).to receive(:broadcast)
  allow($redis_client).to receive(:set)
  end

  it 'streams paginated results and updates cache' do
    # Simulate two pages of results
    allow(service_double).to receive(:call).and_return(
      { json: { data: [ { title: 'Song 1' }, { title: 'Song 2' } ], pagination: { next_page: 2 } } },
      { json: { data: [ { title: 'Song 3' } ], pagination: { next_page: nil } } }
    )

    expect(ActionCable.server).to receive(:broadcast).with("artist_songs_#{search_id}", hash_including(songs: [ 'Song 1', 'Song 2' ], done: false)).ordered
    expect(ActionCable.server).to receive(:broadcast).with("artist_songs_#{search_id}", hash_including(songs: [ 'Song 3' ], done: false)).ordered
    expect(ActionCable.server).to receive(:broadcast).with("artist_songs_#{search_id}", hash_including(songs: [], done: true)).ordered

  expect($redis_client).to receive(:set).with("artist_songs_titles:#{artist_id}", [ 'Song 1', 'Song 2', 'Song 3' ].to_json, ex: 600)

    described_class.perform_now(search_id: search_id, artist_id: artist_id, session_data: session_data)
  end
end
