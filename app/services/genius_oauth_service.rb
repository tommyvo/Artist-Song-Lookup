require "net/http"
require "uri"
require "json"

class GeniusOauthService
  TOKEN_URL = "https://api.genius.com/oauth/token"

  def self.exchange_code_for_token(code, redirect_uri)
    client_id = ENV["GENIUS_CLIENT_ID"]
    client_secret = ENV["GENIUS_CLIENT_SECRET"]
    uri = URI(TOKEN_URL)
    res = Net::HTTP.post_form(uri, {
      "code" => code,
      "client_id" => client_id,
      "client_secret" => client_secret,
      "redirect_uri" => redirect_uri,
      "grant_type" => "authorization_code"
    })
    JSON.parse(res.body)
  rescue => e
    Rails.logger.error("Genius OAuth error: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    { "error" => "An error occurred while connecting to Genius. Please try again later." }
  end
end
