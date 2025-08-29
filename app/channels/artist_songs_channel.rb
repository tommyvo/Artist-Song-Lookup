class ArtistSongsChannel < ApplicationCable::Channel
  def subscribed
    # Each client subscribes to a unique stream for their search
    stream_from "artist_songs_#{params[:search_id]}"
  end
end
