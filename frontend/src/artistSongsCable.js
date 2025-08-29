import consumer from "./consumer";

export function subscribeToArtistSongs(searchId, onSongs, onDone) {
  return consumer.subscriptions.create(
    { channel: "ArtistSongsChannel", search_id: searchId },
    {
      received(data) {
        if (data.songs && data.songs.length > 0) {
          onSongs(data.songs, data.page);
        }
        if (data.done) {
          onDone && onDone();
        }
      }
    }
  );
}
