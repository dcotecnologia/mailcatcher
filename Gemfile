# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "eventmachine", "~> 1.2.7"
gem "faye-websocket", "~> 0.11.3"
gem "mail", "~> 2.8.1"
gem "net-smtp", "~> 0.5.0"
gem "rake", "~> 13.2.1"
gem "sinatra", "~> 3.2.0"
gem "sinatra-basic-auth"
gem "sqlite3", "~> 2.6.0"
gem "thin"

group :development do
  gem "pry-byebug"
  gem "rerun", require: false
end

group :development, :lint do
  gem "rubocop"
  gem "rubocop-capybara", require: false
  gem "rubocop-i18n", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-thread_safety", "~> 0.6.0", require: false
end

group :test do
  gem "brakeman"
  gem "bundler-audit"
  gem "capybara"
  gem "capybara-screenshot"
  gem "rspec"
  gem "selenium-webdriver"
end
