require "faraday"
require "json"

module Umami
  # The Client class provides methods to interact with the Umami API.
  #
  # @see https://umami.is/docs/api Umami API Documentation
  class Client
    attr_reader :uri_base, :request_timeout

    # Initialize a new Umami API client
    #
    # @param options [Hash] options to create a client with.
    # @option options [String] :uri_base The base URI for the Umami API
    # @option options [Integer] :request_timeout Request timeout in seconds
    # @option options [String] :access_token Access token for authentication
    # @option options [String] :username Username for authentication (only for self-hosted instances)
    # @option options [String] :password Password for authentication (only for self-hosted instances)
    def initialize(options = {})
      @config = options[:config] || Umami.configuration
      @config.validate!  # Validate the configuration before using it

      @uri_base = options[:uri_base] || @config.uri_base
      @request_timeout = options[:request_timeout] || @config.request_timeout
      @access_token = options[:access_token] || @config.access_token
      @username = options[:username] || @config.username
      @password = options[:password] || @config.password

      validate_client_options

      authenticate if @access_token.nil?
    end

    # Check if the client is configured for Umami Cloud
    #
    # @return [Boolean] true if using Umami Cloud, false otherwise
    def cloud?
      @uri_base == Umami::Configuration::UMAMI_CLOUD_URL
    end

    # Check if the client is configured for a self-hosted Umami instance
    #
    # @return [Boolean] true if using a self-hosted instance, false otherwise
    def self_hosted?
      !cloud?
    end

    # Verify the authentication token
    #
    # @return [Hash] Token verification result
    # @see https://umami.is/docs/api/authentication#post-/api/auth/verify
    def verify_token
      get("/api/auth/verify")
    end

    # Authentication endpoints

    # Authenticate with the Umami API using username and password
    #
    # This method is called automatically when initializing the client if an access token is not provided.
    # It sets the @access_token instance variable upon successful authentication.
    #
    # @raise [Umami::AuthenticationError] if username or password is missing, or if authentication fails
    # @return [void]
    # @see https://umami.is/docs/api/authentication#post-/api/auth/login
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

    # -------- Users endpoints --------

    # Create a new user
    #
    # @param username [String] The user's username
    # @param password [String] The user's password
    # @param role [String] The user's role ('admin' or 'user')
    # @return [Hash] Created user details
    # @see https://umami.is/docs/api/users-api#post-/api/users
    def create_user(username, password, role)
      post("/api/users", { username: username, password: password, role: role })
    end

    # Get all users (admin access required)
    #
    # @return [Array<Hash>] List of all users
    # @see https://umami.is/docs/api/users-api#get-/api/admin/users
    def users
      get("/api/admin/users")
    end

    # Get a user by ID
    #
    # @param user_id [String] The user's ID
    # @return [Hash] User details
    # @see https://umami.is/docs/api/users-api#get-/api/users/:userid
    def user(user_id)
      get("/api/users/#{user_id}")
    end

    # Update a user
    #
    # @param user_id [String] The user's ID
    # @param params [Hash] User parameters to update
    # @option params [String] :username The user's new username
    # @option params [String] :password The user's new password
    # @option params [String] :role The user's new role
    # @return [Hash] Updated user details
    # @see https://umami.is/docs/api/users-api#post-/api/users/:userid
    def update_user(user_id, params = {})
      post("/api/users/#{user_id}", params)
    end

    # Delete a user
    #
    # @param user_id [String] The user's ID
    # @return [String] Confirmation message
    # @see https://umami.is/docs/api/users-api#delete-/api/users/:userid
    def delete_user(user_id)
      delete("/api/users/#{user_id}")
    end

    # Get all websites for a user
    #
    # @param user_id [String] The user's ID
    # @param params [Hash] Query parameters
    # @option params [String] :query Search text
    # @option params [Integer] :page Page number
    # @option params [Integer] :pageSize Number of results per page
    # @option params [String] :orderBy Column to order by
    # @return [Array<Hash>] List of user's websites
    # @see https://umami.is/docs/api/users-api#get-/api/users/:userid/websites
    def user_websites(user_id, params = {})
      get("/api/users/#{user_id}/websites", params)
    end

    # Get all teams for a user
    #
    # @param user_id [String] The user's ID
    # @param params [Hash] Query parameters
    # @option params [String] :query Search text
    # @option params [Integer] :page Page number
    # @option params [Integer] :pageSize Number of results per page
    # @option params [String] :orderBy Column to order by
    # @return [Array<Hash>] List of user's teams
    # @see https://umami.is/docs/api/users-api#get-/api/users/:userid/teams
    def user_teams(user_id, params = {})
      get("/api/users/#{user_id}/teams", params)
    end

    # -------- Teams endpoints --------

    # Create a new team
    #
    # @param name [String] The team's name
    # @return [Hash] Created team details
    # @see https://umami.is/docs/api/teams-api#post-/api/teams
    def create_team(name)
      post("/api/teams", { name: name })
    end

    # Get all teams
    #
    # @param params [Hash] Query parameters
    # @option params [String] :query Search text
    # @option params [Integer] :page Page number
    # @option params [Integer] :pageSize Number of results per page
    # @option params [String] :orderBy Column to order by
    # @return [Array<Hash>] List of teams
    # @see https://umami.is/docs/api/teams-api#get-/api/teams
    def teams(params = {})
      get("/api/teams", params)
    end

    # Join a team
    #
    # @param access_code [String] The team's access code
    # @return [Hash] Joined team details
    # @see https://umami.is/docs/api/teams-api#post-/api/teams/join
    def join_team(access_code)
      post("/api/teams/join", { accessCode: access_code })
    end

    # Get a team by ID
    #
    # @param team_id [String] The team's ID
    # @return [Hash] Team details
    # @see https://umami.is/docs/api/teams-api#get-/api/teams/:teamid
    def team(team_id)
      get("/api/teams/#{team_id}")
    end

    # Update a team
    #
    # @param team_id [String] The team's ID
    # @param params [Hash] Team parameters to update
    # @option params [String] :name The team's new name
    # @option params [String] :accessCode The team's new access code
    # @return [Hash] Updated team details
    # @see https://umami.is/docs/api/teams-api#post-/api/teams/:teamid
    def update_team(team_id, params = {})
      post("/api/teams/#{team_id}", params)
    end

    # Delete a team
    #
    # @param team_id [String] The team's ID
    # @return [String] Confirmation message
    # @see https://umami.is/docs/api/teams-api#delete-/api/teams/:teamid
    def delete_team(team_id)
      delete("/api/teams/#{team_id}")
    end

    # Get all users in a team
    #
    # @param team_id [String] The team's ID
    # @param params [Hash] Query parameters
    # @option params [String] :query Search text
    # @option params [Integer] :page Page number
    # @option params [Integer] :pageSize Number of results per page
    # @option params [String] :orderBy Column to order by
    # @return [Array<Hash>] List of team users
    # @see https://umami.is/docs/api/teams-api#get-/api/teams/:teamid/users
    def team_users(team_id, params = {})
      get("/api/teams/#{team_id}/users", params)
    end

    # Add a user to a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @param role [String] The user's role in the team
    # @return [Hash] Added team user details
    # @see https://umami.is/docs/api/teams-api#post-/api/teams/:teamid/users
    def add_team_user(team_id, user_id, role)
      post("/api/teams/#{team_id}/users", { userId: user_id, role: role })
    end

    # Get a user in a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @return [Hash] Team user details
    # @see https://umami.is/docs/api/teams-api#get-/api/teams/:teamid/users/:userid
    def team_user(team_id, user_id)
      get("/api/teams/#{team_id}/users/#{user_id}")
    end

    # Update a user's role in a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @param role [String] The user's new role
    # @return [String] Confirmation message
    # @see https://umami.is/docs/api/teams-api#post-/api/teams/:teamid/users/:userid
    def update_team_user(team_id, user_id, role)
      post("/api/teams/#{team_id}/users/#{user_id}", { role: role })
    end

    # Remove a user from a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @return [String] Confirmation message
    # @see https://umami.is/docs/api/teams-api#delete-/api/teams/:teamid/users/:userid
    def delete_team_user(team_id, user_id)
      delete("/api/teams/#{team_id}/users/#{user_id}")
    end

    # Get all websites for a team
    #
    # @param team_id [String] The team's ID
    # @param params [Hash] Query parameters
    # @option params [String] :query Search text
    # @option params [Integer] :page Page number
    # @option params [Integer] :pageSize Number of results per page
    # @option params [String] :orderBy Column to order by
    # @return [Array<Hash>] List of team websites
    # @see https://umami.is/docs/api/teams-api#get-/api/teams/:teamid/websites
    def team_websites(team_id, params = {})
      get("/api/teams/#{team_id}/websites", params)
    end

    # -------- Websites endpoints --------

    # Get all websites
    #
    # @param params [Hash] Query parameters
    # @option params [String] :query Search text
    # @option params [Integer] :page Page number
    # @option params [Integer] :pageSize Number of results per page
    # @option params [String] :orderBy Column to order by
    # @return [Array<Hash>] List of websites
    # @see https://umami.is/docs/api/websites-api#get-/api/websites
    def websites(params = {})
      get("/api/websites", params)
    end

    # Create a new website
    #
    # @param params [Hash] Website parameters
    # @option params [String] :domain The full domain of the tracked website
    # @option params [String] :name The name of the website in Umami
    # @option params [String] :shareId A unique string to enable a share url (optional)
    # @option params [String] :teamId The ID of the team the website will be created under (optional)
    # @return [Hash] Created website details
    # @see https://umami.is/docs/api/websites-api#post-/api/websites
    def create_website(params = {})
      post("/api/websites", params)
    end

    # Get a website by ID
    #
    # @param id [String] The website's ID
    # @return [Hash] Website details
    # @see https://umami.is/docs/api/websites-api#get-/api/websites/:websiteid
    def website(id)
      get("/api/websites/#{id}")
    end

    # Update a website
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Website parameters to update
    # @option params [String] :name The name of the website in Umami
    # @option params [String] :domain The full domain of the tracked website
    # @option params [String] :shareId A unique string to enable a share url
    # @return [Hash] Updated website details
    # @see https://umami.is/docs/api/websites-api#post-/api/websites/:websiteid
    def update_website(website_id, params = {})
      post("/api/websites/#{website_id}", params)
    end

    # Delete a website
    #
    # @param website_id [String] The website's ID
    # @return [String] Confirmation message
    # @see https://umami.is/docs/api/websites-api#delete-/api/websites/:websiteid
    def delete_website(website_id)
      delete("/api/websites/#{website_id}")
    end

    # Reset a website's data
    #
    # @param website_id [String] The website's ID
    # @return [String] Confirmation message
    # @see https://umami.is/docs/api/websites-api#post-/api/websites/:websiteid/reset
    def reset_website(website_id)
      post("/api/websites/#{website_id}/reset")
    end

    # -------- Website stats endpoints --------

    # Get website statistics
    #
    # @param id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @option params [String] :url Name of URL
    # @option params [String] :referrer Name of referrer
    # @option params [String] :title Name of page title
    # @option params [String] :query Name of query
    # @option params [String] :event Name of event
    # @option params [String] :os Name of operating system
    # @option params [String] :browser Name of browser
    # @option params [String] :device Name of device
    # @option params [String] :country Name of country
    # @option params [String] :region Name of region/state/province
    # @option params [String] :city Name of city
    # @return [Hash] Website statistics
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/stats
    def website_stats(id, params = {})
      get("/api/websites/#{id}/stats", params)
    end

    # Get active visitors for a website
    #
    # @param id [String] The website's ID
    # @return [Hash] Number of active visitors
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/active
    def website_active_visitors(id)
      get("/api/websites/#{id}/active")
    end

    # Get website events
    #
    # @param id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @option params [String] :unit Time unit (year | month | hour | day)
    # @option params [String] :timezone Timezone (ex. America/Los_Angeles)
    # @option params [String] :url Name of URL
    # @return [Array<Hash>] Website events
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/events
    def website_events(id, params = {})
      get("/api/websites/#{id}/events", params)
    end

    # Get website pageviews
    #
    # @param id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @option params [String] :unit Time unit (year | month | hour | day)
    # @option params [String] :timezone Timezone (ex. America/Los_Angeles)
    # @option params [String] :url Name of URL
    # @option params [String] :referrer Name of referrer
    # @option params [String] :title Name of page title
    # @option params [String] :os Name of operating system
    # @option params [String] :browser Name of browser
    # @option params [String] :device Name of device
    # @option params [String] :country Name of country
    # @option params [String] :region Name of region/state/province
    # @option params [String] :city Name of city
    # @return [Hash] Website pageviews and sessions
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/pageviews
    def website_pageviews(id, params = {})
      get("/api/websites/#{id}/pageviews", params)
    end

    # Get website metrics
    #
    # @param id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @option params [String] :type Metrics type (url | referrer | browser | os | device | country | event)
    # @option params [String] :url Name of URL
    # @option params [String] :referrer Name of referrer
    # @option params [String] :title Name of page title
    # @option params [String] :query Name of query
    # @option params [String] :event Name of event
    # @option params [String] :os Name of operating system
    # @option params [String] :browser Name of browser
    # @option params [String] :device Name of device
    # @option params [String] :country Name of country
    # @option params [String] :region Name of region/state/province
    # @option params [String] :city Name of city
    # @option params [String] :language Name of language
    # @option params [Integer] :limit Number of results to return (default: 500)
    # @return [Array<Hash>] Website metrics
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/metrics
    def website_metrics(id, params = {})
      get("/api/websites/#{id}/metrics", params)
    end

    # Get event data events
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @option params [String] :event Event Name filter
    # @return [Array<Hash>] Event data events
    # @see https://umami.is/docs/api/event-data#get-/api/event-data/events
    def event_data_events(website_id, params = {})
      get("/api/event-data/events", params.merge(websiteId: website_id))
    end


    # -------- Event data endpoints --------

    # Get event data fields
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @return [Array<Hash>] Event data fields
    # @see https://umami.is/docs/api/event-data#get-/api/event-data/fields
    def event_data_fields(website_id, params = {})
      get("/api/event-data/fields", params.merge(websiteId: website_id))
    end

    # Get event data stats
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date
    # @option params [Integer] :endAt Timestamp (in ms) of end date
    # @return [Array<Hash>] Event data stats
    # @see https://umami.is/docs/api/event-data#get-/api/event-data/stats
    def event_data_stats(website_id, params = {})
      get("/api/event-data/stats", params.merge(websiteId: website_id))
    end

    # -------- Sending stats endpoint --------

    # Send an event
    #
    # @param payload [Hash] Event payload
    # @option payload [String] :hostname Name of host
    # @option payload [String] :language Language of visitor (ex. "en-US")
    # @option payload [String] :referrer Referrer URL
    # @option payload [String] :screen Screen resolution (ex. "1920x1080")
    # @option payload [String] :title Page title
    # @option payload [String] :url Page URL
    # @option payload [String] :website Website ID
    # @option payload [String] :name Name of the event
    # @option payload [Hash] :data Additional data for the event
    # @return [Hash] Response from the server
    # @see https://umami.is/docs/api/sending-stats
    def send_event(payload)
      post("/api/send", { type: "event", payload: payload })
    end


    private

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
