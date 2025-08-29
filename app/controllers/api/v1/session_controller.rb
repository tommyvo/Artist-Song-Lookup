module Api
  module V1
    class SessionController < ApplicationController
      def show
        Rails.logger.info("Session status API called for session id: #{session.id || 'unknown'}")

        if session[:genius_access_token].present?
          render json: { authenticated: true }
        else
          render json: { authenticated: false }, status: :unauthorized
        end
      end
    end
  end
end
