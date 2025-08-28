require "net/http"
require "uri"
require "json"

class GeniusApiService
  BASE_URL = "https://api.genius.com"

  def self.search_artists(query, access_token, page: 1, per_page: 10)
    uri = URI("#{BASE_URL}/search")
    uri.query = URI.encode_www_form(q: query, page: page, per_page: per_page)

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 5) do |http|
      http.request(req)
    end

    JSON.parse(res.body)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("Genius API timeout: #{e.class} - #{e.message}")
    { "error" => "The request to Genius timed out. Please try again later." }
  rescue => e
    Rails.logger.error("Genius API error: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    { "error" => "An unexpected error occurred while contacting Genius. Please try again later." }
  end
end
