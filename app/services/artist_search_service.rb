require "retryable"

class ArtistSearchService
  # Handles all artist search logic, including validation, pagination, and formatting
  def initialize(params, session)
    @params = params
    @session = session
  end

  def call
    query = @params[:q].to_s.strip
    return error_response("Missing or invalid artist name") if query.blank? || query.length > 100

    page = @params[:page].to_i
    page = 1 if page < 1
    per_page = @params[:per_page].to_i
    per_page = 10 if per_page < 1 || per_page > 50

    access_token = @session[:genius_access_token]
    return error_response("Not authenticated with Genius", :unauthorized) if access_token.blank? || access_token.length > 200

    cache_key = "artist_search:#{query.downcase}:page=#{page}:per_page=#{per_page}"

    # Only check cache after validation and authentication
    if query.present? && access_token.present?
      cached = $redis_client.get(cache_key)
      if cached
        result = JSON.parse(cached, symbolize_names: true)
        result[:status] = result[:status].to_sym if result[:status].is_a?(String)
        return result
      end
    end

    api_response = nil
    begin
      Retryable.retryable(tries: 3, sleep: ->(n) { 0.5 * (2 ** (n - 1)) }, on: [ Timeout::Error, Errno::ETIMEDOUT ]) do |retries, exception|
        if exception
          Rails.logger.info("[ArtistSearchService] Retrying Genius API call (attempt \\#{retries + 1}) due to: \\#{exception.class} - \\#{exception.message}")
        end
        api_response = GeniusApiService.search_artists(query, access_token, page: page, per_page: per_page)
        if api_response["error"]
          # Only retry on timeout/network errors, not on 4xx/5xx from Genius
          raise Timeout::Error if api_response["error"].to_s =~ /timeout|timed out|connection|network/i
        end
      end
    rescue => e
      return error_response("Genius API error: #{e.class} - #{e.message}", :bad_gateway)
    end

    if api_response["error"]
      return error_response(api_response["error"], :bad_gateway)
    end

    hits = api_response.dig("response", "hits") || []
    total = hits.size
    paginated = Kaminari.paginate_array(hits).page(page).per(per_page)

    result = {
      status: :ok,
      json: {
        success: true,
        data: paginated.map { |hit| hit["result"].transform_keys(&:to_sym) },
        error: nil,
        pagination: {
          page: paginated.current_page,
          per_page: paginated.limit_value,
          total: total,
          total_pages: paginated.total_pages
        }
      }
    }

    # Only cache successful lookups (no error, at least one hit)
    if hits.any?
      $redis_client.set(cache_key, result.to_json, ex: 600) # 10 minutes
    end

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
