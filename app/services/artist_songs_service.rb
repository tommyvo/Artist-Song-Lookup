class ArtistSongsService
  # Handles fetching songs for a Genius artist ID
  def initialize(params, session)
    @params = params
    @session = session
  end

  def call
    artist_id = @params[:genius_artist_id].to_s.strip
    return error_response("Missing or invalid genius_artist_id") if artist_id.blank? || artist_id !~ /^\d+$/

    page = @params[:page].to_i
    page = 1 if page < 1
    per_page = @params[:per_page].to_i
    per_page = 10 if per_page < 1 || per_page > 50

    access_token = @session[:genius_access_token]
    return error_response("Not authenticated with Genius", :unauthorized) if access_token.blank? || access_token.length > 200

    cache_key = "artist_songs:#{artist_id}:page=#{page}:per_page=#{per_page}"

    # Only check cache after validation and authentication
    if artist_id.present? && access_token.present?
      cached = RedisClient.get(cache_key)
      if cached
        result = JSON.parse(cached, symbolize_names: true)
        result[:status] = result[:status].to_sym if result[:status].is_a?(String)
        return result
      end
    end

    api_response = GeniusApiService.fetch_artist_songs(artist_id, access_token, page: page, per_page: per_page)
    if api_response["error"]
      return error_response(api_response["error"], :bad_gateway)
    end

    songs = (api_response.dig("response", "songs") || []).map { |s| s.transform_keys(&:to_sym) }
    total = api_response.dig("response", "next_page") ? nil : songs.size
    # Genius API paginates with next_page, so we can't always know total

    result = {
      status: :ok,
      json: {
        success: true,
        data: songs,
        error: nil,
        pagination: {
          page: page,
          per_page: per_page,
          total: total,
          next_page: api_response.dig("response", "next_page")
        }
      }
    }
    RedisClient.set(cache_key, result.to_json, ex: 600) # 10 minutes
    result
  end

  private

  def error_response(message, status = :bad_request)
    {
      status: status,
      json: {
        success: false,
        data: [],
        error: message,
        pagination: {}
      }
    }
  end
end
