module Umami
  # Base error class for Umami-related errors
  class Error < StandardError; end

  # Error raised when there's a configuration issue
  class ConfigurationError < Error; end

  # Error raised when authentication fails
  class AuthenticationError < Error; end

  # Base error class for API-related errors
  class APIError < Error; end

  # Error raised when a resource is not found
  class NotFoundError < APIError; end

  # Error raised for client-side errors (4xx status codes)
  class ClientError < APIError; end

  # Error raised for server-side errors (5xx status codes)
  class ServerError < APIError; end
end
