class OauthController < ApplicationController
  def callback
    code = params[:code]
    redirect_uri = ENV["GENIUS_REDIRECT_URI"]
    if code.blank?
      render plain: "Missing code parameter", status: :bad_request and return
    end

    response = GeniusOauthService.exchange_code_for_token(code, redirect_uri)

    if response["access_token"]
      # Store the access token in session or database as needed
      session[:genius_access_token] = response["access_token"]
      render plain: "OAuth successful! Access token received."
    else
      error_message = response["error"] || response["error_description"] || "Unknown error"
      render plain: "OAuth failed: #{error_message}", status: :unauthorized
    end
  end

  def authorize
    client_id = ENV["GENIUS_CLIENT_ID"]
    redirect_uri = ENV["GENIUS_REDIRECT_URI"]
    auth_url = "https://api.genius.com/oauth/authorize?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=me&state=secure_random_state&response_type=code"
    redirect_to auth_url, allow_other_host: true
  end
end
