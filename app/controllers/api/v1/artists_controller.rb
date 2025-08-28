module Api
  module V1
    class ArtistsController < ApplicationController
      def search
        # Sanitize and validate parameters
        query = params[:q].to_s.strip
        if query.blank? || query.length > 100
          render json: {
            success: false,
            data: [],
            error: "Missing or invalid artist name",
            pagination: {}
          }, status: :bad_request and return
        end

        page = params[:page].to_i
        page = 1 if page < 1
        per_page = params[:per_page].to_i
        per_page = 10 if per_page < 1 || per_page > 50

        # Only permit expected params (defense-in-depth)
        params.permit(:q, :page, :per_page)

        access_token = session[:genius_access_token]
        if access_token.blank? || access_token.length > 200
          render json: {
            success: false,
            data: [],
            error: "Not authenticated with Genius",
            pagination: {}
          }, status: :unauthorized and return
        end

        api_response = GeniusApiService.search_artists(query, access_token, page: page, per_page: per_page)

        if api_response["error"]
          render json: {
            success: false,
            data: [],
            error: api_response["error"],
            pagination: {}
          }, status: :bad_gateway and return
        end

        # Genius API returns hits in response['response']['hits']
        hits = api_response.dig("response", "hits") || []
        total = hits.size
        paginated = Kaminari.paginate_array(hits).page(page).per(per_page)

        render json: {
          success: true,
          data: paginated.map { |hit| hit["result"] },
          error: nil,
          pagination: {
            page: paginated.current_page,
            per_page: paginated.limit_value,
            total: total,
            total_pages: paginated.total_pages
          }
        }
      end
    end
  end
end
