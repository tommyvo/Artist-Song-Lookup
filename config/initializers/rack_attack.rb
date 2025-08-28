# config/initializers/rack_attack.rb

class Rack::Attack
  # Allow all local traffic
  safelist("allow-localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  # Throttle requests to /api/v1/artists/search by IP: 10 requests per minute
  throttle("api/artist_search/ip", limit: 10, period: 60) do |req|
    if req.path == "/api/v1/artists/search" && req.get?
      req.ip
    end
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    [ 429, { "Content-Type" => "application/json" },
      [ { success: false, data: [], error: "Rate limit exceeded. Please try again later.", pagination: {} }.to_json ] ]
  end
end
