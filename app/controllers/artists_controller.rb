class ArtistsController < ApplicationController
  def search
    query = params[:q]
    page = params[:page] || 1
    per_page = params[:per_page] || 10

    if query.blank?
      render json: { error: "Missing artist name" }, status: :bad_request and return
    end

    access_token = session[:genius_access_token]
    if access_token.blank?
      render json: { error: "Not authenticated with Genius" }, status: :unauthorized and return
    end

    api_response = GeniusApiService.search_artists(query, access_token, page: page, per_page: per_page)

    if api_response["error"]
      render json: { error: api_response["error"] }, status: :bad_gateway and return
    end

    # Genius API returns hits in response['response']['hits']
    hits = api_response.dig("response", "hits") || []
    total = hits.size
    paginated = Kaminari.paginate_array(hits).page(page).per(per_page)

    render json: {
      artists: paginated.map { |hit| hit["result"] },
      pagination: {
        page: paginated.current_page,
        per_page: paginated.limit_value,
        total: total,
        total_pages: paginated.total_pages
      }
    }
  end
end
