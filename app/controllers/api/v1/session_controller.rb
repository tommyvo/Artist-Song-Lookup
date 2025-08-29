module Api
  module V1
    class SessionController < ApplicationController
      def show
        if session[:genius_access_token].present?
          render json: { authenticated: true }
        else
          render json: { authenticated: false }, status: :unauthorized
        end
      end
    end
  end
end
