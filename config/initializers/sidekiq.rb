# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: "#{ENV['REDIS_URL']}/#{ENV['REDIS_SIDEKIQ_DB']}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "#{ENV['REDIS_URL']}/#{ENV['REDIS_SIDEKIQ_DB']}" }
end

# CONFIG = YAML.load_file("#{Rails.root}/config/redis.yml")[Rails.env]

# Sidekiq.configure_server do |config|
#   config.redis = CONFIG
# end

# Sidekiq.configure_client do |config|
#   config.redis = CONFIG
# end

# # Restore Sidekiq UI Web
# require 'sidekiq/web'
# Sidekiq::Web.set :sessions, false
