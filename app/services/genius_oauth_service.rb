require 'net/http'
require 'uri'
require 'json'

class GeniusOauthService
  TOKEN_URL = 'https://api.genius.com/oauth/token'

  def self.exchange_code_for_token(code, redirect_uri)
    client_id = ENV['GENIUS_CLIENT_ID']
    client_secret = ENV['GENIUS_CLIENT_SECRET']
    uri = URI(TOKEN_URL)
    res = Net::HTTP.post_form(uri, {
      'code' => code,
      'client_id' => client_id,
      'client_secret' => client_secret,
      'redirect_uri' => redirect_uri,
      'grant_type' => 'authorization_code'
    })
    JSON.parse(res.body)
  rescue => e
    { 'error' => e.message }
  end
end
