# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Umami::TestCase
  def test_error_hierarchy
    assert Umami::Error < StandardError
    assert Umami::ConfigurationError < Umami::Error
    assert Umami::AuthenticationError < Umami::Error
    assert Umami::APIError < Umami::Error
    assert Umami::NotFoundError < Umami::APIError
    assert Umami::ClientError < Umami::APIError
    assert Umami::ServerError < Umami::APIError
  end

  def test_error_can_be_raised_with_message
    error = assert_raises(Umami::Error) do
      raise Umami::Error, "Test error message"
    end
    assert_equal "Test error message", error.message
  end

  def test_configuration_error_message
    error = assert_raises(Umami::ConfigurationError) do
      raise Umami::ConfigurationError, "Invalid config"
    end
    assert_equal "Invalid config", error.message
  end

  def test_authentication_error_message
    error = assert_raises(Umami::AuthenticationError) do
      raise Umami::AuthenticationError, "Auth failed"
    end
    assert_equal "Auth failed", error.message
  end

  def test_api_error_message
    error = assert_raises(Umami::APIError) do
      raise Umami::APIError, "API request failed"
    end
    assert_equal "API request failed", error.message
  end

  def test_not_found_error_message
    error = assert_raises(Umami::NotFoundError) do
      raise Umami::NotFoundError, "Resource not found"
    end
    assert_equal "Resource not found", error.message
  end

  def test_client_error_message
    error = assert_raises(Umami::ClientError) do
      raise Umami::ClientError, "Client error"
    end
    assert_equal "Client error", error.message
  end

  def test_server_error_message
    error = assert_raises(Umami::ServerError) do
      raise Umami::ServerError, "Server error"
    end
    assert_equal "Server error", error.message
  end

  def test_can_rescue_api_error_to_catch_subtypes
    # NotFoundError should be rescuable as APIError
    rescued = false
    begin
      raise Umami::NotFoundError, "Not found"
    rescue Umami::APIError
      rescued = true
    end
    assert rescued, "NotFoundError should be rescuable as APIError"

    # ClientError should be rescuable as APIError
    rescued = false
    begin
      raise Umami::ClientError, "Client error"
    rescue Umami::APIError
      rescued = true
    end
    assert rescued, "ClientError should be rescuable as APIError"

    # ServerError should be rescuable as APIError
    rescued = false
    begin
      raise Umami::ServerError, "Server error"
    rescue Umami::APIError
      rescued = true
    end
    assert rescued, "ServerError should be rescuable as APIError"
  end

  def test_can_rescue_error_to_catch_all_umami_errors
    [
      Umami::ConfigurationError,
      Umami::AuthenticationError,
      Umami::APIError,
      Umami::NotFoundError,
      Umami::ClientError,
      Umami::ServerError
    ].each do |error_class|
      rescued = false
      begin
        raise error_class, "Test"
      rescue Umami::Error
        rescued = true
      end
      assert rescued, "#{error_class} should be rescuable as Umami::Error"
    end
  end
end
