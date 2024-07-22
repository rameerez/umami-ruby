require "faraday"
require "json"

module Umami
  class Client
    attr_reader :uri_base, :request_timeout

    def initialize(options = {})
      @config = options[:config] || Umami.configuration
      @uri_base = options[:uri_base] || @config.uri_base
      @request_timeout = options[:request_timeout] || @config.request_timeout
      @access_token = options[:access_token] || @config.access_token
      @username = options[:username] || @config.username
      @password = options[:password] || @config.password

      validate_client_options

      authenticate if @access_token.nil?
    end

    def websites
      get("/api/websites")
    end

    def website(id)
      get("/api/websites/#{id}")
    end

    def website_stats(id, params = {})
      get("/api/websites/#{id}/stats", params)
    end

    def authenticate
      raise Umami::AuthenticationError, "Username and password are required for authentication" if @username.nil? || @password.nil?

      response = connection.post("/api/auth/login") do |req|
        req.body = { username: @username, password: @password }.to_json
      end

      data = JSON.parse(response.body)
      @access_token = data["token"]
    rescue Faraday::Error, JSON::ParserError => e
      raise Umami::AuthenticationError, "Authentication failed: #{e.message}"
    end

    def verify_token
      get("/api/auth/verify")
    end

    def cloud?
      @uri_base == Umami::Configuration::UMAMI_CLOUD_URL
    end

    private

    def get(path, params = {})
      response = connection.get(path, params)
      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise Umami::APIError, "API request failed: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new(url: uri_base) do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
        faraday.headers["Authorization"] = "Bearer #{@access_token}" if @access_token
        faraday.options.timeout = request_timeout
      end
    end

    def validate_client_options
      if @access_token && @uri_base.nil?
        @uri_base = Umami::Configuration::UMAMI_CLOUD_URL
        Umami.logger.info "No URI base provided with access token. Using Umami Cloud URL: #{@uri_base}"
      end

      raise Umami::ConfigurationError, "URI base is required for self-hosted instances" if @uri_base.nil? && !@access_token

      if cloud? && (@username || @password)
        raise Umami::ConfigurationError, "Username/password authentication is not supported for Umami Cloud"
      end

      if @access_token && (@username || @password)
        Umami.logger.warn "Both access token and credentials provided. Access token will be used."
        @username = nil
        @password = nil
      end

      if @uri_base != Umami::Configuration::UMAMI_CLOUD_URL && !@access_token && !@username && !@password
        raise Umami::ConfigurationError, "Authentication is required for self-hosted instances"
      end
    end
  end
end
