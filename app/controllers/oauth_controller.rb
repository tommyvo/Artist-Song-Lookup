class OauthController < ApplicationController
  def callback
    result = OauthCallbackService.new(params, session).call
    render plain: result[:body], status: result[:status]
  end

  def authorize
    client_id = ENV["GENIUS_CLIENT_ID"]
    redirect_uri = ENV["GENIUS_REDIRECT_URI"]
    auth_url = "https://api.genius.com/oauth/authorize?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=me&state=secure_random_state&response_type=code"
    redirect_to auth_url, allow_other_host: true
  end
end
