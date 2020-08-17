Sidekiq.configure_server do |config|
  # either default to localhost or pick up URL from REDIS_URL
  #config.redis = { url: 'redis://localhost:6379/0' }
  config.logger.level = Logger::DEBUG
end

Sidekiq.configure_client do |config|
  # either default to localhost or pick up URL from REDIS_URL
  #config.redis = { url: 'redis://localhost:6379/0' }
  config.logger.level = Logger::DEBUG
end