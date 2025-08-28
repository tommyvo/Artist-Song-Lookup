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
  rescue Net::OpenTimeout, Net::ReadTimeout
    { "error" => "timeout" }
  rescue => e
    { "error" => e.message }
  end
end
