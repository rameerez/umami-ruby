# frozen_string_literal: true

require "test_helper"

class UmamiTest < Umami::TestCase
  def test_version_is_defined
    refute_nil Umami::VERSION
    assert_match(/\A\d+\.\d+\.\d+/, Umami::VERSION)
  end

  def test_configuration_returns_configuration_instance
    assert_kind_of Umami::Configuration, Umami.configuration
  end

  def test_configure_yields_configuration
    Umami.configure do |config|
      assert_kind_of Umami::Configuration, config
    end
  end

  def test_configure_sets_values
    Umami.configure do |config|
      config.uri_base = "https://test.example.com"
      config.access_token = "test_token"
      config.request_timeout = 60
    end

    assert_equal "https://test.example.com", Umami.configuration.uri_base
    assert_equal "test_token", Umami.configuration.access_token
    assert_equal 60, Umami.configuration.request_timeout
  end

  def test_reset_creates_new_configuration
    Umami.configure do |config|
      config.uri_base = "https://test.example.com"
      config.access_token = "test_token"
    end

    old_config = Umami.configuration
    Umami.reset

    refute_same old_config, Umami.configuration
    assert_nil Umami.configuration.uri_base
    assert_nil Umami.configuration.access_token
  end

  def test_logger_returns_logger_instance
    assert_kind_of Logger, Umami.logger
    assert_equal "Umami", Umami.logger.progname
  end

  def test_logger_can_be_set
    custom_logger = Logger.new($stdout)
    custom_logger.progname = "Custom"

    Umami.logger = custom_logger
    assert_equal "Custom", Umami.logger.progname

    # Reset for other tests
    Umami.logger = nil
  end

  def test_client_creates_new_client_instance
    Umami.configure do |config|
      config.uri_base = "https://test.example.com"
      config.access_token = "test_token"
    end

    client = Umami.client
    assert_kind_of Umami::Client, client
  end

  def test_client_accepts_options
    Umami.configure do |config|
      config.uri_base = "https://default.example.com"
      config.access_token = "default_token"
    end

    client = Umami.client(uri_base: "https://override.example.com")
    assert_equal "https://override.example.com", client.uri_base
  end
end
