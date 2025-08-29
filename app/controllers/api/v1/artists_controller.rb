module Api
  module V1
    class ArtistsController < ApplicationController
      def search
        begin
          params.permit(:q)
          query = params[:q].to_s.strip.downcase
          return render json: { success: false, error: "Missing or invalid artist name", data: [] }, status: :bad_request if query.blank?

          # Cache artist id for search term
          artist_id_cache_key = "artist_id:#{query}"
          artist_id = RedisClient.get(artist_id_cache_key)

          unless artist_id
            # Use ArtistSearchService to get artist id from Genius
            search_result = ArtistSearchService.new({ q: query }, session).call
            first_hit = search_result.dig(:json, :data)&.first
            artist_id = first_hit&.dig(:primary_artist, :id) || first_hit&.dig(:primary_artist_id) || first_hit&.dig(:id)

            if artist_id.nil?
              return render json: { success: false, error: "Artist not found", data: [] }, status: :not_found
            end
            RedisClient.set(artist_id_cache_key, artist_id, ex: 600)
          end

          # Cache song titles for artist id
          songs_cache_key = "artist_songs_titles:#{artist_id}"
          song_titles = RedisClient.get(songs_cache_key)

          if song_titles
            song_titles = JSON.parse(song_titles)
          else
            # Fetch all songs for artist id, paginating through all pages
            all_titles = []
            page = 1

            loop do
              songs_result = ArtistSongsService.new({ genius_artist_id: artist_id, page: page, per_page: 50 }, session).call
              songs = songs_result.dig(:json, :data) || []
              all_titles += songs.map { |s| s[:title] || s["title"] }.compact
              next_page = songs_result.dig(:json, :pagination, :next_page)
              break unless next_page
              page = next_page
            end

            song_titles = all_titles.uniq
            RedisClient.set(songs_cache_key, song_titles.to_json, ex: 600)
          end

          render json: { success: true, data: song_titles }, status: :ok
        rescue => e
          render json: { error: "Internal server error" }, status: :internal_server_error
        end
      end
    end
  end
end
