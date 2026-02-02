# frozen_string_literal: true

source "https://rubygems.org"

# Runtime dependencies are specified in umami-ruby.gemspec
gemspec

# Tooling
gem "rake", "~> 13.0"

group :development do
  # Documentation
  gem "yard"
  gem "redcarpet"

  # Code quality
  gem "rubocop", "~> 1.0"
  gem "rubocop-minitest", "~> 0.35"
  gem "rubocop-performance", "~> 1.0"
end

group :development, :test do
  gem "minitest", "~> 6.0"
  gem "minitest-mock"
  gem "minitest-reporters", "~> 1.6"
  gem "simplecov", require: false

  # HTTP mocking
  gem "vcr", "~> 6.0"
  gem "webmock", "~> 3.0"

  # Environment
  gem "dotenv", "~> 3.0"
end
