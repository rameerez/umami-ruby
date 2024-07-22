module Umami
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class APIError < Error; end
  class NotFoundError < APIError; end
  class ClientError < APIError; end
  class ServerError < APIError; end
end
