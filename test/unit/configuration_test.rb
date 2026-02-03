# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Umami::TestCase
  def test_default_values
    config = Umami::Configuration.new
    assert_nil config.uri_base
    assert_equal 120, config.request_timeout
    assert_nil config.access_token
    assert_nil config.username
    assert_nil config.password
  end

  def test_uri_base_removes_trailing_slash
    config = Umami::Configuration.new
    config.uri_base = "https://example.com/"
    assert_equal "https://example.com", config.uri_base
  end

  def test_uri_base_handles_nil
    config = Umami::Configuration.new
    config.uri_base = nil
    assert_nil config.uri_base
  end

  def test_access_token_clears_credentials
    config = Umami::Configuration.new
    config.credentials = { username: "user", password: "pass" }
    config.access_token = "token123"

    assert_equal "token123", config.access_token
    assert_nil config.username
    assert_nil config.password
  end

  def test_credentials_require_both_username_and_password
    config = Umami::Configuration.new

    error = assert_raises(Umami::ConfigurationError) do
      config.credentials = { username: "user" }
    end
    assert_match(/username and password are required/i, error.message)

    error = assert_raises(Umami::ConfigurationError) do
      config.credentials = { password: "pass" }
    end
    assert_match(/username and password are required/i, error.message)
  end

  def test_credentials_clears_access_token
    config = Umami::Configuration.new
    config.access_token = "token123"
    config.credentials = { username: "user", password: "pass" }

    assert_nil config.access_token
    assert_equal "user", config.username
    assert_equal "pass", config.password
  end

  def test_cloud_detection_with_only_access_token
    config = Umami::Configuration.new
    config.access_token = "token123"

    assert config.cloud?
  end

  def test_not_cloud_with_uri_base_set
    config = Umami::Configuration.new
    config.uri_base = "https://my-umami.com"
    config.access_token = "token123"

    refute config.cloud?
  end

  def test_validate_sets_cloud_url_when_cloud
    config = Umami::Configuration.new
    config.access_token = "token123"
    config.validate!

    assert_equal Umami::Configuration::UMAMI_CLOUD_URL, config.uri_base
  end

  def test_validate_rejects_credentials_for_cloud
    config = Umami::Configuration.new
    config.uri_base = Umami::Configuration::UMAMI_CLOUD_URL
    config.credentials = { username: "user", password: "pass" }

    error = assert_raises(Umami::ConfigurationError) do
      config.validate!
    end
    assert_match(/not supported for Umami Cloud/i, error.message)
  end

  def test_validate_requires_auth_for_self_hosted
    config = Umami::Configuration.new
    config.uri_base = "https://my-umami.com"

    error = assert_raises(Umami::ConfigurationError) do
      config.validate!
    end
    assert_match(/Authentication is required/i, error.message)
  end

  def test_validate_warns_when_both_token_and_credentials_provided
    config = Umami::Configuration.new
    config.uri_base = "https://my-umami.com"
    config.access_token = "token123"
    # Manually set credentials to simulate both being present
    config.instance_variable_set(:@username, "user")
    config.instance_variable_set(:@password, "pass")
    config.instance_variable_set(:@dirty, true)

    # Should not raise, but should clear credentials
    config.validate!
    assert_nil config.username
    assert_nil config.password
  end

  def test_cloud_url_constants
    assert_equal "https://api.umami.is", Umami::Configuration::UMAMI_CLOUD_URL
    assert_equal "https://cloud.umami.is", Umami::Configuration::UMAMI_CLOUD_SEND_URL
  end
end
