# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'
gem 'rails', '~> 6.0.2', '>= 6.0.2.2'

gem 'bootsnap', '>= 1.4.2', require: false

gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'rubocop-rails', require: false
gem 'httparty', '~> 0.18.0'
gem 'woocommerce_api', '~> 1.4'

gem 'sassc-rails', '~> 2.0.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'

gem 'jquery-minicolors-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails', '~> 2.7'
end

group :development do
  gem 'capistrano',         require: false
  gem 'capistrano-rvm',     require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-rails-console', '~> 2.3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma',   require: false
  gem 'capistrano-sidekiq'
  gem 'erb2haml'
  gem 'haml_lint', '~> 0.27.0', require: false
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Requests to APIs
gem 'rest-client'

# Jobs
gem 'redis'
gem 'redis-namespace'
gem 'redis-rails'
gem 'sidekiq', '~> 5.2.8'
gem 'sidekiq-scheduler'
gem 'sinatra', require: nil
