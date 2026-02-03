# frozen_string_literal: true

# SimpleCov must be loaded BEFORE any application code
# Configuration is auto-loaded from .simplecov file
require "simplecov"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Core testing libraries
require "minitest/autorun"
require "minitest/mock"
require "minitest/reporters"

# HTTP mocking
require "webmock/minitest"
require "vcr"

# Environment
require "dotenv"

# Load environment variables from .env.test.local (gitignored) and .env.test
Dotenv.load(".env.test.local", ".env.test")

# Load the gem
require "umami"

# Configure Minitest reporters
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# VCR Configuration
VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: ENV.fetch("VCR_RECORD_MODE", "once").to_sym,
    # Match on method and path only (ignore time-based query params)
    match_requests_on: [:method, :path]
  }

  # Filter sensitive data
  config.filter_sensitive_data("<UMAMI_ACCESS_TOKEN>") { ENV["UMAMI_ACCESS_TOKEN"] }

  # Filter Authorization header
  config.before_record do |interaction|
    interaction.request.headers["Authorization"]&.map! { "<FILTERED>" }
  end

  # Register path matcher that ignores query params
  config.register_request_matcher :path do |request_1, request_2|
    uri1 = URI.parse(request_1.uri)
    uri2 = URI.parse(request_2.uri)
    uri1.path == uri2.path
  end

  # Allow localhost for any local testing
  config.ignore_localhost = true
end

# Disable all real network connections by default (VCR cassettes required)
WebMock.disable_net_connect!(allow_localhost: true)

# Base test class with common setup
class Umami::TestCase < Minitest::Test
  def setup
    Umami.reset
    WebMock.reset!
  end

  def teardown
    Umami.reset
    WebMock.reset!
  end

  # Helper to get a configured client for tests
  # Uses the URI and credentials that match the recorded VCR cassettes
  def configured_client
    Umami.configure do |config|
      config.uri_base = test_uri_base
      config.access_token = test_access_token
    end
    Umami::Client.new
  end

  # URI base must match the cassettes (recorded from self-hosted instance)
  def test_uri_base
    "https://api.umami-test.example"
  end

  def test_access_token
    # This is a placeholder - VCR will intercept requests and use cassettes
    "vcr_test_token"
  end

  # Test website IDs (must match the website IDs in the recorded cassettes)
  def test_website_id
    # Primary test website
    "00000000-0000-4000-a000-000000000001"
  end

  def test_website_id_alt
    # Secondary test website
    "00000000-0000-4000-a000-000000000002"
  end

  # Time range helpers
  def seven_days_ago_ms
    ((Time.now - 7 * 24 * 60 * 60).to_f * 1000).to_i
  end

  def now_ms
    (Time.now.to_f * 1000).to_i
  end

  def thirty_days_ago_ms
    ((Time.now - 30 * 24 * 60 * 60).to_f * 1000).to_i
  end
end

# Custom assertions
module CustomAssertions
  def assert_valid_uuid(value, msg = nil)
    uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
    assert_match uuid_regex, value.to_s, msg || "Expected #{value.inspect} to be a valid UUID"
  end

  def assert_valid_timestamp(value, msg = nil)
    assert_kind_of Integer, value, msg || "Expected #{value.inspect} to be a timestamp (Integer)"
    assert value > 0, msg || "Expected #{value.inspect} to be a positive timestamp"
  end

  def assert_paginated_response(response, msg = nil)
    assert_kind_of Hash, response, msg || "Expected paginated response to be a Hash"
    assert response.key?("data"), msg || "Expected paginated response to have 'data' key"
    assert_kind_of Array, response["data"], msg || "Expected 'data' to be an Array"
  end
end

class Umami::TestCase
  include CustomAssertions
end
