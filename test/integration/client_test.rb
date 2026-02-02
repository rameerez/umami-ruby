# frozen_string_literal: true

require "test_helper"

class ClientTest < Umami::TestCase
  def test_initializes_with_access_token
    Umami.configure do |config|
      config.uri_base = "https://test.example.com"
      config.access_token = "test_token"
    end

    client = Umami::Client.new
    assert_equal "https://test.example.com", client.uri_base
    assert_equal 120, client.request_timeout
  end

  def test_initializes_with_options_override
    Umami.configure do |config|
      config.uri_base = "https://default.example.com"
      config.access_token = "default_token"
    end

    client = Umami::Client.new(
      uri_base: "https://override.example.com",
      request_timeout: 60
    )

    assert_equal "https://override.example.com", client.uri_base
    assert_equal 60, client.request_timeout
  end

  def test_cloud_detection
    Umami.configure do |config|
      config.access_token = "test_token"
    end

    client = Umami::Client.new
    assert client.cloud?
    refute client.self_hosted?
  end

  def test_self_hosted_detection
    Umami.configure do |config|
      config.uri_base = "https://my-umami.example.com"
      config.access_token = "test_token"
    end

    client = Umami::Client.new
    refute client.cloud?
    assert client.self_hosted?
  end

  def test_raises_configuration_error_without_auth
    Umami.configure do |config|
      config.uri_base = "https://my-umami.example.com"
    end

    error = assert_raises(Umami::ConfigurationError) do
      Umami::Client.new
    end
    assert_match(/Authentication is required/i, error.message)
  end
end
