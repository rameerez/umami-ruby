module Umami
  # Configuration class for the Umami client.
  #
  # @example Configure for Umami Cloud
  #   Umami.configure do |config|
  #     config.access_token = "your_api_key"
  #   end
  #
  # @example Configure for self-hosted with access token
  #   Umami.configure do |config|
  #     config.uri_base = "https://your-umami-instance.com"
  #     config.access_token = "your_access_token"
  #   end
  #
  # @example Configure for self-hosted with credentials
  #   Umami.configure do |config|
  #     config.uri_base = "https://your-umami-instance.com"
  #     config.credentials = { username: "user", password: "pass" }
  #   end
  #
  # @example Configure with custom timeout
  #   Umami.configure do |config|
  #     config.access_token = "your_api_key"
  #     config.request_timeout = 60  # 60 seconds instead of default 120
  #   end
  class Configuration
    # Base URL for Umami Cloud API (used for most API calls)
    # @return [String]
    UMAMI_CLOUD_URL = "https://api.umami.is".freeze

    # Base URL for Umami Cloud send endpoint (used only for send_event)
    # @note The send endpoint uses a different base URL than other API calls
    # @return [String]
    UMAMI_CLOUD_SEND_URL = "https://cloud.umami.is".freeze

    # @!attribute [rw] uri_base
    #   @return [String, nil] Base URL for the Umami API
    # @!attribute [rw] request_timeout
    #   @return [Integer] Request timeout in seconds (default: 120)
    # @!attribute [rw] access_token
    #   @return [String, nil] Access token for API authentication
    # @!attribute [r] username
    #   @return [String, nil] Username for self-hosted authentication (set via credentials=)
    # @!attribute [r] password
    #   @return [String, nil] Password for self-hosted authentication (set via credentials=)
    attr_reader :uri_base, :request_timeout, :access_token, :username, :password

    # Initialize a new Configuration with default values
    def initialize
      @uri_base = nil
      @request_timeout = 120
      @access_token = nil
      @username = nil
      @password = nil
      @dirty = false
    end

    # Set the base URI for the Umami API
    # @param url [String] The base URL (trailing slash will be removed)
    def uri_base=(url)
      @uri_base = url&.chomp('/')
      @dirty = true
    end

    # Set the access token for API authentication
    # @note Setting an access token clears any username/password credentials
    # @param token [String] The access token
    def access_token=(token)
      @access_token = token
      @username = nil
      @password = nil
      @dirty = true
    end

    # Set username/password credentials for self-hosted authentication
    # @note Setting credentials clears any access token
    # @param creds [Hash] Credentials hash with :username and :password keys
    # @raise [Umami::ConfigurationError] if username or password is missing
    def credentials=(creds)
      raise Umami::ConfigurationError, "Both username and password are required" unless creds[:username] && creds[:password]

      @username = creds[:username]
      @password = creds[:password]
      @access_token = nil
      @dirty = true
    end

    # Set the request timeout in seconds
    # @param timeout [Integer] Timeout in seconds
    def request_timeout=(timeout)
      @request_timeout = timeout
      @dirty = true
    end

    # Check if configured for Umami Cloud
    # @return [Boolean] true if using Umami Cloud (access token without custom URI)
    def cloud?
      @access_token && @uri_base.nil?
    end

    # Validate the configuration and apply defaults
    # @raise [Umami::ConfigurationError] if configuration is invalid
    def validate!
      return unless @dirty

      if cloud?
        @uri_base = UMAMI_CLOUD_URL
        Umami.logger.info "Using Umami Cloud (#{UMAMI_CLOUD_URL})"
      end

      if @uri_base == UMAMI_CLOUD_URL && (@username || @password)
        raise Umami::ConfigurationError, "Username/password authentication is not supported for Umami Cloud"
      end

      if @access_token && (@username || @password)
        Umami.logger.warn "Both access token and credentials provided. Access token will be used."
        @username = nil
        @password = nil
      end

      if @uri_base && @uri_base != UMAMI_CLOUD_URL && !@access_token && !@username && !@password
        raise Umami::ConfigurationError, "Authentication is required for self-hosted instances"
      end

      @dirty = false
    end
  end
end
