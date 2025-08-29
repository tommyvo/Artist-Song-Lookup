# Redis client for caching API responses
require "redis"

$redis_client = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
