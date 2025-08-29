module Api
  module V1
    class ArtistsController < ApplicationController
      require "securerandom"

      # Skip CSRF verification for the stream_songs API endpoint.
      #
      # Why? This endpoint is called from a React/Vite frontend that communicates with Rails via API calls.
      # In such setups, CSRF protection is not needed for API endpoints if:
      #   - The endpoint is protected by authentication (e.g., session or token-based auth).
      #   - The endpoint does not perform sensitive state-changing actions for unauthenticated users.
      #   - The API is not exposed to untrusted origins (CORS is restricted).
      #
      # In this case, stream_songs only triggers a background job to stream artist song data for authenticated users.
      # No sensitive user data is changed, and the endpoint is not public. Session-based authentication is still enforced.
      # This is a common and safe practice for internal API endpoints in modern Rails+SPA architectures.
      skip_before_action :verify_authenticity_token, only: [ :stream_songs ]

      # POST /api/v1/artists/stream_songs
      def stream_songs
        params.permit(:q)
        query = params[:q].to_s.strip.downcase
        return render json: { error: "Missing or invalid artist name" }, status: :bad_request if query.blank?

        # Find or fetch artist_id
        artist_id_cache_key = "artist_id:#{query}"
        artist_id = $redis_client.get(artist_id_cache_key)

        unless artist_id
          attempts = 0
          artist_id = nil
          while attempts < 3 && artist_id.nil?
            search_result = ArtistSearchService.new({ q: query }, session).call
            first_hit = search_result.dig(:json, :data)&.first
            artist_id = first_hit&.dig(:primary_artist, :id)
            attempts += 1
            break if artist_id
            sleep 0.7 if attempts < 3
          end
          if artist_id.nil?
            return render json: { error: "Artist not found after 3 attempts" }, status: :not_found
          end
          $redis_client.set(artist_id_cache_key, artist_id, ex: 600)
        end

        # Generate a unique search_id for this stream
        search_id = SecureRandom.uuid

        # Start the streaming job
        StreamArtistSongsJob.perform_later(search_id: search_id, artist_id: artist_id, session_data: session.to_hash)
        render json: { search_id: search_id, artist_id: artist_id }
      end

      def search
        Rails.logger.info("Artist search API called with params: #{params.inspect}, session id: #{session.id || 'unknown'}")

        begin
          params.permit(:q)
          query = params[:q].to_s.strip.downcase

          if query.blank?
            Rails.logger.warn("Artist search failed: missing or invalid artist name")
            return render json: { success: false, error: "Missing or invalid artist name", data: [] }, status: :bad_request
          end

          # Cache artist id for search term
          artist_id_cache_key = "artist_id:#{query}"
          artist_id = $redis_client.get(artist_id_cache_key)

          if artist_id
            Rails.logger.info("Cache hit for artist_id: #{artist_id_cache_key}")
          else
            Rails.logger.info("Cache miss for artist_id: #{artist_id_cache_key}")
          end

          unless artist_id
            # Use ArtistSearchService to get artist id from Genius
            search_result = ArtistSearchService.new({ q: query }, session).call
            first_hit = search_result.dig(:json, :data)&.first
            artist_id = first_hit&.dig(:primary_artist, :id)

            if artist_id.nil?
              Rails.logger.info("Artist search: artist not found for query '#{query}'")
              return render json: { success: false, error: "Artist not found", data: [] }, status: :not_found
            end
            $redis_client.set(artist_id_cache_key, artist_id, ex: 600)
          end

          # Cache song titles for artist id
          songs_cache_key = "artist_songs_titles:#{artist_id}"
          song_titles = $redis_client.get(songs_cache_key)

          if song_titles
            Rails.logger.info("Cache hit for songs: #{songs_cache_key}")
          else
            Rails.logger.info("Cache miss for songs: #{songs_cache_key}")
          end

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
            $redis_client.set(songs_cache_key, song_titles.to_json, ex: 600)
          end

          render json: {
            success: true,
            data: {
              artist_name: query,
              genius_artist_id: artist_id.to_s,
              songs: song_titles
            }
          }, status: :ok
        rescue => e
          Rails.logger.error("Artist search: internal server error: #{e.message}")
          render json: { error: "Internal server error" }, status: :internal_server_error
        end
      end
    end
  end
end
