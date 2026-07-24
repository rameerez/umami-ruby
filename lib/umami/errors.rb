module Umami
  # Base error class for Umami-related errors
  class Error < StandardError; end

  # Error raised when there's a configuration issue
  class ConfigurationError < Error; end

  # Base error class for API-related errors
  class APIError < Error; end

  # Error raised when authentication fails — a rejected login, a login
  # response without a token, or an API request answered 401/403 (an
  # expired or revoked token on a long-lived client, insufficient
  # permissions). Deliberately a subclass of APIError since 0.2.1:
  # before that, HTTP 401/403 surfaced as ClientError, so callers who
  # `rescue Umami::APIError` were already catching them — subclassing
  # APIError keeps those rescues working while giving auth failures
  # their own class to match on.
  class AuthenticationError < APIError; end

  # Error raised when a resource is not found
  class NotFoundError < APIError; end

  # Error raised for client-side errors (4xx status codes)
  class ClientError < APIError; end

  # Error raised for server-side errors (5xx status codes)
  class ServerError < APIError; end
end
