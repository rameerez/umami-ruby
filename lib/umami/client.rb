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

    def cloud?
      @uri_base == Umami::Configuration::UMAMI_CLOUD_URL
    end

    def self_hosted?
      !cloud?
    end

    # Authentication endpoints

    def verify_token
      get("/api/auth/verify")
    end


    # Users endpoints
    def create_user(username, password, role)
      post("/api/users", { username: username, password: password, role: role })
    end

    def users
      get("/api/admin/users")
    end

    def user(user_id)
      get("/api/users/#{user_id}")
    end

    def update_user(user_id, params = {})
      post("/api/users/#{user_id}", params)
    end

    def delete_user(user_id)
      delete("/api/users/#{user_id}")
    end

    def user_websites(user_id, params = {})
      get("/api/users/#{user_id}/websites", params)
    end

    def user_teams(user_id, params = {})
      get("/api/users/#{user_id}/teams", params)
    end


    # Teams endpoints
    def create_team(name)
      post("/api/teams", { name: name })
    end

    def teams(params = {})
      get("/api/teams", params)
    end

    def join_team(access_code)
      post("/api/teams/join", { accessCode: access_code })
    end

    def team(team_id)
      get("/api/teams/#{team_id}")
    end

    def update_team(team_id, params = {})
      post("/api/teams/#{team_id}", params)
    end

    def delete_team(team_id)
      delete("/api/teams/#{team_id}")
    end

    def team_users(team_id, params = {})
      get("/api/teams/#{team_id}/users", params)
    end

    def add_team_user(team_id, user_id, role)
      post("/api/teams/#{team_id}/users", { userId: user_id, role: role })
    end

    def team_user(team_id, user_id)
      get("/api/teams/#{team_id}/users/#{user_id}")
    end

    def update_team_user(team_id, user_id, role)
      post("/api/teams/#{team_id}/users/#{user_id}", { role: role })
    end

    def delete_team_user(team_id, user_id)
      delete("/api/teams/#{team_id}/users/#{user_id}")
    end

    def team_websites(team_id, params = {})
      get("/api/teams/#{team_id}/websites", params)
    end


    # Websites endpoints

    def websites
      get("/api/websites")
    end

    def create_website(params = {})
      post("/api/websites", params)
    end

    def website(id)
      get("/api/websites/#{id}")
    end

    def update_website(website_id, params = {})
      post("/api/websites/#{website_id}", params)
    end

    def reset_website(website_id)
      post("/api/websites/#{website_id}/reset")
    end


    # Website stats endpoints

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

    private

    def get(path, params = {})
      response = connection.get(path, params)
      JSON.parse(response.body)
    rescue Faraday::Error => e
      handle_error(e)
    end

    def post(path, body = {})
      response = connection.post(path, body.to_json)
      JSON.parse(response.body)
    rescue Faraday::Error => e
      handle_error(e)
    end

    def delete(path)
      response = connection.delete(path)
      response.body == "ok" ? "ok" : JSON.parse(response.body)
    rescue Faraday::Error => e
      handle_error(e)
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

    def handle_error(error)
      case error
      when Faraday::ResourceNotFound
        raise Umami::NotFoundError, "Resource not found: #{error.message}"
      when Faraday::ClientError
        raise Umami::ClientError, "Client error: #{error.message}"
      when Faraday::ServerError
        raise Umami::ServerError, "Server error: #{error.message}"
      else
        raise Umami::APIError, "API request failed: #{error.message}"
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
