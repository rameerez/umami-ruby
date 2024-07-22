module Umami
  class Configuration
    UMAMI_CLOUD_URL = "https://api.umami.is".freeze

    attr_reader :uri_base, :request_timeout, :access_token, :username, :password

    def initialize
      @uri_base = nil
      @request_timeout = 120
      @access_token = nil
      @username = nil
      @password = nil
      @dirty = false
    end

    def uri_base=(url)
      @uri_base = url&.chomp('/')
      @dirty = true
    end

    def access_token=(token)
      @access_token = token
      @username = nil
      @password = nil
      @dirty = true
    end

    def credentials=(creds)
      raise Umami::ConfigurationError, "Both username and password are required" unless creds[:username] && creds[:password]

      @username = creds[:username]
      @password = creds[:password]
      @access_token = nil
      @dirty = true
    end

    def cloud?
      @access_token && @uri_base.nil?
    end

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
