# frozen_string_literal: true

require "test_helper"

class ClientInitializationTest < Umami::TestCase
  def test_uses_global_configuration_by_default
    Umami.configure do |config|
      config.uri_base = "https://global.example.com"
      config.access_token = "global_token"
      config.request_timeout = 60
    end

    client = Umami::Client.new

    assert_equal "https://global.example.com", client.uri_base
    assert_equal 60, client.request_timeout
  end

  def test_options_override_global_configuration
    Umami.configure do |config|
      config.uri_base = "https://global.example.com"
      config.access_token = "global_token"
      config.request_timeout = 60
    end

    client = Umami::Client.new(
      uri_base: "https://override.example.com",
      access_token: "override_token",
      request_timeout: 30
    )

    assert_equal "https://override.example.com", client.uri_base
    assert_equal 30, client.request_timeout
  end

  def test_cloud_returns_true_for_cloud_url
    Umami.configure do |config|
      config.access_token = "cloud_token"
    end

    client = Umami::Client.new
    assert client.cloud?
    refute client.self_hosted?
  end

  def test_cloud_returns_false_for_self_hosted
    Umami.configure do |config|
      config.uri_base = "https://my-umami.example.com"
      config.access_token = "self_hosted_token"
    end

    client = Umami::Client.new
    refute client.cloud?
    assert client.self_hosted?
  end

  def test_auto_sets_cloud_url_with_only_access_token
    Umami.configure do |config|
      config.access_token = "my_cloud_token"
    end

    client = Umami::Client.new

    assert_equal Umami::Configuration::UMAMI_CLOUD_URL, client.uri_base
    assert client.cloud?
  end

  def test_default_timeout_is_120_seconds
    Umami.configure do |config|
      config.uri_base = "https://example.com"
      config.access_token = "token"
    end

    client = Umami::Client.new
    assert_equal 120, client.request_timeout
  end

  def test_rejects_credentials_for_cloud
    Umami.reset
    Umami.configure do |config|
      config.uri_base = Umami::Configuration::UMAMI_CLOUD_URL
      config.credentials = { username: "user", password: "pass" }
    end

    error = assert_raises(Umami::ConfigurationError) do
      Umami::Client.new
    end
    assert_match(/not supported for Umami Cloud/i, error.message)
  end

  def test_requires_uri_base_for_self_hosted_without_token
    Umami.reset

    error = assert_raises(Umami::ConfigurationError) do
      Umami.configure do |config|
        # Neither access_token nor uri_base
      end
      Umami::Client.new
    end

    # Either ConfigurationError from validation or from validate_client_options
    assert error.is_a?(Umami::ConfigurationError)
  end
end
