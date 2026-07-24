# frozen_string_literal: true

require "test_helper"

# The FULL username/password lifecycle: login, then actually USE the client.
#
# This file exists because of the <= 0.2.0 regression: `authenticate` built
# (and memoized) the Faraday connection to POST the login itself — before
# `@access_token` existed — and Faraday bakes headers in at build time, so
# every request AFTER a successful login went out without an Authorization
# header and died with 401. The old suite covered failed logins and missing
# credentials but never "login, then call an endpoint", which is the only
# path where the bug is visible. These tests pin the whole flow.
class AuthenticationFlowTest < Minitest::Test
  URI_BASE = "https://self-hosted.umami.is"
  TOKEN = "test-jwt-token-abc123"

  def setup
    # ⚠️ In this suite the WebMock request REGISTRY survives across tests
    # (VCR's `hook_into :webmock` in test_helper keeps webmock/minitest's
    # automatic per-test reset from firing), which silently breaks
    # `assert_requested ..., times:` — counts accumulate across the whole
    # run. Reset explicitly BEFORE stubbing; the other test files get away
    # without it only because they never assert request counts.
    WebMock.reset!

    Umami.reset
    Umami.configure do |config|
      config.uri_base = URI_BASE
      config.credentials = { username: "admin", password: "umami" }
    end

    stub_request(:post, "#{URI_BASE}/api/auth/login")
      .with(body: { username: "admin", password: "umami" }.to_json)
      .to_return(
        status: 200,
        body: { token: TOKEN, user: { id: "user-1", username: "admin" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def teardown
    Umami.reset
  end

  # THE regression test: the request that follows a username/password login
  # must carry the Bearer token obtained by that login.
  def test_requests_after_login_carry_the_bearer_token
    api_stub = stub_request(:get, "#{URI_BASE}/api/me")
      .with(headers: { "Authorization" => "Bearer #{TOKEN}" })
      .to_return(
        status: 200,
        body: { id: "user-1", username: "admin", role: "admin" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Umami::Client.new
    response = client.me

    assert_equal "admin", response["username"]
    # Belt and braces: webmock only matches the stub when the header is
    # present, but assert explicitly so a future header regression reads
    # as "token never sent" instead of an obscure NotFound.
    assert_requested api_stub
  end

  def test_multiple_requests_reuse_the_same_authenticated_connection
    stub_request(:get, "#{URI_BASE}/api/websites")
      .with(headers: { "Authorization" => "Bearer #{TOKEN}" })
      .to_return(
        status: 200,
        body: { data: [], count: 0 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Umami::Client.new
    2.times { client.websites }

    # One login serves the whole client lifetime — re-authenticating per
    # request would hammer the login endpoint (and Umami rate-limits it).
    assert_requested :post, "#{URI_BASE}/api/auth/login", times: 1
    assert_requested :get, "#{URI_BASE}/api/websites", times: 2
  end

  def test_login_response_without_a_token_raises_authentication_error
    stub_request(:post, "#{URI_BASE}/api/auth/login")
      .to_return(
        status: 200,
        body: { user: { id: "user-1" } }.to_json, # 200 but no token
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Umami::AuthenticationError) do
      Umami::Client.new
    end
    assert_match(/no token/i, error.message)
  end

  def test_expired_token_surfaces_as_authentication_error_not_client_error
    stub_request(:get, "#{URI_BASE}/api/me")
      .to_return(
        status: 401,
        body: { error: "Token expired" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Umami::Client.new

    error = assert_raises(Umami::AuthenticationError) { client.me }
    # Callers can `rescue Umami::AuthenticationError` to re-login without
    # losing broad `rescue Umami::APIError` handlers (subclass since 0.2.1).
    assert_kind_of Umami::APIError, error
  end
end
