# frozen_string_literal: true

require "test_helper"

class ErrorHandlingTest < Umami::TestCase
  def setup
    super
    # Configure client for error tests
    Umami.configure do |config|
      config.uri_base = "https://api.test.umami.is"
      config.access_token = "test_token"
    end
    @client = Umami::Client.new
  end

  # ==================== Authentication Errors ====================

  def test_handles_401_unauthorized
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_return(
        status: 401,
        body: '{"error": "Unauthorized"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::ClientError) do
      @client.me
    end
    assert_match(/401|Unauthorized|Client error/i, error.message)
  end

  def test_handles_403_forbidden
    stub_request(:get, "https://api.test.umami.is/api/admin/users")
      .to_return(
        status: 403,
        body: '{"error": "Forbidden"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::ClientError) do
      @client.admin_users
    end
    assert_match(/403|Forbidden|Client error/i, error.message)
  end

  # ==================== Not Found Errors ====================

  def test_handles_404_not_found
    stub_request(:get, "https://api.test.umami.is/api/websites/nonexistent-id")
      .to_return(
        status: 404,
        body: '{"error": "Not found"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::NotFoundError) do
      @client.website("nonexistent-id")
    end
    assert_match(/not found/i, error.message)
  end

  # ==================== Client Errors (4xx) ====================

  def test_handles_400_bad_request
    stub_request(:get, %r{api\.test\.umami\.is/api/websites/.*/stats})
      .to_return(
        status: 400,
        body: '{"error": "Invalid parameters"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::ClientError) do
      @client.website_stats("test-id", startAt: "invalid", endAt: "invalid")
    end
    assert_match(/400|Client error/i, error.message)
  end

  def test_handles_422_unprocessable_entity
    stub_request(:post, "https://api.test.umami.is/api/websites")
      .to_return(
        status: 422,
        body: '{"error": "Validation failed"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::ClientError) do
      @client.create_website(name: "", domain: "")
    end
    assert_match(/422|Client error/i, error.message)
  end

  def test_handles_429_rate_limit
    stub_request(:get, "https://api.test.umami.is/api/websites")
      .to_return(
        status: 429,
        body: '{"error": "Rate limit exceeded"}',
        headers: {
          "Content-Type" => "application/json",
          "Retry-After" => "60"
        }
      )

    error = assert_raises(Umami::ClientError) do
      @client.websites
    end
    assert_match(/429|Client error/i, error.message)
  end

  # ==================== Server Errors (5xx) ====================

  def test_handles_500_server_error
    stub_request(:get, "https://api.test.umami.is/api/websites")
      .to_return(
        status: 500,
        body: '{"error": "Internal server error"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::ServerError) do
      @client.websites
    end
    assert_match(/500|Server error/i, error.message)
  end

  def test_handles_502_bad_gateway
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_return(
        status: 502,
        body: "Bad Gateway",
        headers: { "Content-Type" => "text/html" }
      )

    error = assert_raises(Umami::ServerError) do
      @client.me
    end
    assert_match(/502|Server error/i, error.message)
  end

  def test_handles_503_service_unavailable
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_return(
        status: 503,
        body: "Service Unavailable",
        headers: { "Content-Type" => "text/html" }
      )

    error = assert_raises(Umami::ServerError) do
      @client.me
    end
    assert_match(/503|Server error/i, error.message)
  end

  # ==================== Network Errors ====================

  def test_handles_connection_timeout
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_timeout

    error = assert_raises(Umami::APIError) do
      @client.me
    end
    assert_match(/timeout|failed/i, error.message)
  end

  def test_handles_connection_refused
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    error = assert_raises(Umami::APIError) do
      @client.me
    end
    assert_match(/Connection|failed/i, error.message)
  end

  def test_handles_ssl_error
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_raise(OpenSSL::SSL::SSLError.new("certificate verify failed"))

    error = assert_raises(Umami::APIError) do
      @client.me
    end
    assert_match(/SSL|certificate|failed/i, error.message)
  end

  # ==================== JSON Parsing Errors ====================

  def test_handles_invalid_json_response
    stub_request(:get, "https://api.test.umami.is/api/me")
      .to_return(
        status: 200,
        body: "not valid json {",
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(JSON::ParserError) do
      @client.me
    end
  end

  # ==================== Authentication Flow Errors ====================

  def test_authenticate_raises_error_without_credentials
    Umami.reset
    Umami.configure do |config|
      config.uri_base = "https://self-hosted.umami.is"
      # No access_token, no username/password
    end

    error = assert_raises(Umami::ConfigurationError) do
      Umami::Client.new
    end
    assert_match(/Authentication is required/i, error.message)
  end

  def test_authenticate_raises_error_on_failed_login
    Umami.reset
    Umami.configure do |config|
      config.uri_base = "https://self-hosted.umami.is"
      config.credentials = { username: "user", password: "wrong" }
    end

    stub_request(:post, "https://self-hosted.umami.is/api/auth/login")
      .with(body: { username: "user", password: "wrong" }.to_json)
      .to_return(
        status: 401,
        body: '{"error": "Invalid credentials"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::AuthenticationError) do
      Umami::Client.new
    end
    assert_match(/Authentication failed/i, error.message)
  end
end
