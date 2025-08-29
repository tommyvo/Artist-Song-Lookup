require "action_cable/engine"

class StreamArtistSongsJob < ApplicationJob
  queue_as :default

  def perform(search_id:, artist_id:, session_data: {})
    # Simulate session for API calls
    session = session_data.with_indifferent_access
    page = 1
    all_titles = []

    loop do
      songs_result = ArtistSongsService.new({ genius_artist_id: artist_id, page: page, per_page: 50 }, session).call
      songs = songs_result.dig(:json, :data) || []
      new_titles = songs.map { |s| s[:title] || s["title"] }.compact
      all_titles += new_titles
      # Broadcast this page to the client
      ActionCable.server.broadcast("artist_songs_#{search_id}", {
        songs: new_titles,
        page: page,
        done: false
      })
      next_page = songs_result.dig(:json, :pagination, :next_page)
      break unless next_page
      page = next_page
    end

    # Final broadcast to indicate completion
    ActionCable.server.broadcast("artist_songs_#{search_id}", {
      songs: [],
      page: page,
      done: true
    })

    # Update cache
    $redis_client.set("artist_songs_titles:#{artist_id}", all_titles.uniq.to_json, ex: 600)
  end
end
