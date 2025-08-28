module Api
  module V1
    class ArtistsController < ApplicationController
      def search
        params.permit(:q, :page, :per_page)
        result = ArtistSearchService.new(params, session).call
        render json: result[:json], status: result[:status]
      end

      def songs
        params.permit(:genius_artist_id, :page, :per_page)
        result = ArtistSongsService.new(params, session).call
        render json: result[:json], status: result[:status]
      end
    end
  end
end
