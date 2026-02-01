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
    # @return [Hash] Token verification result containing user information
    # @see https://umami.is/docs/api/authentication#post-/api/auth/verify
    def verify_token
      post("/api/auth/verify")
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

    # -------- Me endpoints --------

    # Get information about the current authenticated user
    #
    # @return [Hash] Current user information including token, authKey, shareToken, and user details
    # @see https://umami.is/docs/api/me#get-/api/me
    def me
      get("/api/me")
    end

    # Get all teams for the current authenticated user
    #
    # @param params [Hash] Query parameters
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of teams with members
    # @see https://umami.is/docs/api/me#get-/api/me/teams
    def my_teams(params = {})
      get("/api/me/teams", params)
    end

    # Get all websites for the current authenticated user
    #
    # @param params [Hash] Query parameters
    # @option params [Boolean] :includeTeams Include websites where user is team owner
    # @return [Hash] Paginated list of websites
    # @see https://umami.is/docs/api/me#get-/api/me/websites
    def my_websites(params = {})
      get("/api/me/websites", params)
    end

    # -------- Admin endpoints --------

    # Get all users (admin access required, self-hosted only)
    #
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page (default: 20)
    # @return [Hash] Paginated list of all users
    # @see https://umami.is/docs/api/admin#get-/api/admin/users
    def admin_users(params = {})
      get("/api/admin/users", params)
    end

    # Get all websites (admin access required, self-hosted only)
    #
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page (default: 20)
    # @return [Hash] Paginated list of all websites
    # @see https://umami.is/docs/api/admin#get-/api/admin/websites
    def admin_websites(params = {})
      get("/api/admin/websites", params)
    end

    # Get all teams (admin access required, self-hosted only)
    #
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page (default: 20)
    # @return [Hash] Paginated list of all teams
    # @see https://umami.is/docs/api/admin#get-/api/admin/teams
    def admin_teams(params = {})
      get("/api/admin/teams", params)
    end

    # -------- Users endpoints --------

    # Create a new user
    #
    # @param username [String] The user's username
    # @param password [String] The user's password
    # @param role [String] The user's role ('admin', 'user', or 'view-only')
    # @param id [String, nil] Optional UUID to assign to the user
    # @return [Hash] Created user details
    # @see https://umami.is/docs/api/users#post-/api/users
    def create_user(username, password, role, id: nil)
      params = { username: username, password: password, role: role }
      params[:id] = id if id
      post("/api/users", params)
    end

    # Get all users (admin access required)
    #
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page (default: 20)
    # @return [Hash] Paginated list of all users
    # @see https://umami.is/docs/api/admin#get-/api/admin/users
    # @deprecated Use {#admin_users} instead
    def users(params = {})
      admin_users(params)
    end

    # Get a user by ID
    #
    # @param user_id [String] The user's ID
    # @return [Hash] User details
    # @see https://umami.is/docs/api/users#get-/api/users/:userid
    def user(user_id)
      get("/api/users/#{user_id}")
    end

    # Update a user
    #
    # @param user_id [String] The user's ID
    # @param params [Hash] User parameters to update
    # @option params [String] :username The user's new username
    # @option params [String] :password The user's new password
    # @option params [String] :role The user's new role ('admin', 'user', or 'view-only')
    # @return [Hash] Updated user details
    # @see https://umami.is/docs/api/users#post-/api/users/:userid
    def update_user(user_id, params = {})
      post("/api/users/#{user_id}", params)
    end

    # Delete a user
    #
    # @param user_id [String] The user's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/users#delete-/api/users/:userid
    def delete_user(user_id)
      delete("/api/users/#{user_id}")
    end

    # Get all websites for a user
    #
    # @param user_id [String] The user's ID
    # @param params [Hash] Query parameters
    # @option params [Boolean] :includeTeams Include team websites
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of user's websites
    # @see https://umami.is/docs/api/users#get-/api/users/:userid/websites
    def user_websites(user_id, params = {})
      get("/api/users/#{user_id}/websites", params)
    end

    # Get all teams for a user
    #
    # @param user_id [String] The user's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of user's teams
    # @see https://umami.is/docs/api/users#get-/api/users/:userid/teams
    def user_teams(user_id, params = {})
      get("/api/users/#{user_id}/teams", params)
    end

    # -------- Teams endpoints --------

    # Create a new team
    #
    # @param name [String] The team's name
    # @return [Hash] Created team details
    # @see https://umami.is/docs/api/teams#post-/api/teams
    def create_team(name)
      post("/api/teams", { name: name })
    end

    # Get all teams
    #
    # @param params [Hash] Query parameters
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of teams
    # @see https://umami.is/docs/api/teams#get-/api/teams
    def teams(params = {})
      get("/api/teams", params)
    end

    # Join a team
    #
    # @param access_code [String] The team's access code
    # @return [Hash] Joined team details
    # @see https://umami.is/docs/api/teams#post-/api/teams/join
    def join_team(access_code)
      post("/api/teams/join", { accessCode: access_code })
    end

    # Get a team by ID
    #
    # @param team_id [String] The team's ID
    # @return [Hash] Team details
    # @see https://umami.is/docs/api/teams#get-/api/teams/:teamid
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
    # @see https://umami.is/docs/api/teams#post-/api/teams/:teamid
    def update_team(team_id, params = {})
      post("/api/teams/#{team_id}", params)
    end

    # Delete a team
    #
    # @param team_id [String] The team's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/teams#delete-/api/teams/:teamid
    def delete_team(team_id)
      delete("/api/teams/#{team_id}")
    end

    # Get all users in a team
    #
    # @param team_id [String] The team's ID
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of team users
    # @see https://umami.is/docs/api/teams#get-/api/teams/:teamid/users
    def team_users(team_id, params = {})
      get("/api/teams/#{team_id}/users", params)
    end

    # Add a user to a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @param role [String] The user's role in the team ('team-manager', 'team-member', or 'team-view-only')
    # @return [Hash] Added team user details
    # @see https://umami.is/docs/api/teams#post-/api/teams/:teamid/users
    def add_team_user(team_id, user_id, role)
      post("/api/teams/#{team_id}/users", { userId: user_id, role: role })
    end

    # Get a user in a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @return [Hash] Team user details
    # @see https://umami.is/docs/api/teams#get-/api/teams/:teamid/users/:userid
    def team_user(team_id, user_id)
      get("/api/teams/#{team_id}/users/#{user_id}")
    end

    # Update a user's role in a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @param role [String] The user's new role ('team-manager', 'team-member', or 'team-view-only')
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/teams#post-/api/teams/:teamid/users/:userid
    def update_team_user(team_id, user_id, role)
      post("/api/teams/#{team_id}/users/#{user_id}", { role: role })
    end

    # Remove a user from a team
    #
    # @param team_id [String] The team's ID
    # @param user_id [String] The user's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/teams#delete-/api/teams/:teamid/users/:userid
    def delete_team_user(team_id, user_id)
      delete("/api/teams/#{team_id}/users/#{user_id}")
    end

    # Get all websites for a team
    #
    # @param team_id [String] The team's ID
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of team websites
    # @see https://umami.is/docs/api/teams#get-/api/teams/:teamid/websites
    def team_websites(team_id, params = {})
      get("/api/teams/#{team_id}/websites", params)
    end

    # -------- Websites endpoints --------

    # Get all websites
    #
    # @param params [Hash] Query parameters
    # @option params [Boolean] :includeTeams Include websites where user is team owner
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of websites
    # @see https://umami.is/docs/api/websites#get-/api/websites
    def websites(params = {})
      get("/api/websites", params)
    end

    # Create a new website
    #
    # @param params [Hash] Website parameters
    # @option params [String] :name The name of the website in Umami (required)
    # @option params [String] :domain The full domain of the tracked website (required)
    # @option params [String] :shareId A unique string to enable a share url (optional)
    # @option params [String] :teamId The ID of the team the website will be created under (optional)
    # @option params [String] :id Force a specific UUID for the website (optional)
    # @return [Hash] Created website details
    # @see https://umami.is/docs/api/websites#post-/api/websites
    def create_website(params = {})
      post("/api/websites", params)
    end

    # Get a website by ID
    #
    # @param website_id [String] The website's ID
    # @return [Hash] Website details
    # @see https://umami.is/docs/api/websites#get-/api/websites/:websiteid
    def website(website_id)
      get("/api/websites/#{website_id}")
    end

    # Update a website
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Website parameters to update
    # @option params [String] :name The name of the website in Umami (required)
    # @option params [String] :domain The full domain of the tracked website (required)
    # @option params [String] :shareId A unique string to enable a share url
    # @return [Hash] Updated website details
    # @see https://umami.is/docs/api/websites#post-/api/websites/:websiteid
    def update_website(website_id, params = {})
      post("/api/websites/#{website_id}", params)
    end

    # Delete a website
    #
    # @param website_id [String] The website's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/websites#delete-/api/websites/:websiteid
    def delete_website(website_id)
      delete("/api/websites/#{website_id}")
    end

    # Reset a website's data
    #
    # @param website_id [String] The website's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/websites#post-/api/websites/:websiteid/reset
    def reset_website(website_id)
      post("/api/websites/#{website_id}/reset")
    end

    # -------- Website stats endpoints --------

    # Get website statistics
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Hash] Website statistics including pageviews, visitors, visits, bounces, totaltime
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/stats
    def website_stats(website_id, params = {})
      get("/api/websites/#{website_id}/stats", params)
    end

    # Get active visitors for a website (last 5 minutes)
    #
    # @param website_id [String] The website's ID
    # @return [Hash] Number of active visitors
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/active
    def website_active_visitors(website_id)
      get("/api/websites/#{website_id}/active")
    end

    # Get website pageviews within a time range
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :unit Time unit for grouping ('minute', 'hour', 'day', 'month', 'year') (required)
    # @option params [String] :timezone Timezone (e.g., 'America/Los_Angeles')
    # @option params [String] :compare Comparison mode ('prev' or 'yoy')
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Hash] Pageviews and sessions arrays with timestamp and count
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/pageviews
    def website_pageviews(website_id, params = {})
      get("/api/websites/#{website_id}/pageviews", params)
    end

    # Get website events within a time range
    #
    # This method returns event data with optional time-series grouping.
    # For paginated event lists with search, use {#website_events_list} instead.
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :unit Time unit for grouping ('minute', 'hour', 'day', 'month', 'year')
    # @option params [String] :timezone Timezone (e.g., 'America/Los_Angeles')
    # @return [Array<Hash>] Website events
    # @see #website_events_list For paginated event list with search
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/events
    def website_events(website_id, params = {})
      get("/api/websites/#{website_id}/events", params)
    end

    # Get website events series within a time range
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :unit Time unit for grouping ('minute', 'hour', 'day', 'month', 'year') (required)
    # @option params [String] :timezone Timezone (e.g., 'America/Los_Angeles')
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Event series with x (event name), t (timestamp), y (count)
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/events/series
    def website_events_series(website_id, params = {})
      get("/api/websites/#{website_id}/events/series", params)
    end

    # Get website metrics
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :type Metrics type (required): 'path', 'entry', 'exit', 'title', 'query', 'referrer', 'channel', 'domain', 'country', 'region', 'city', 'browser', 'os', 'device', 'language', 'screen', 'event', 'hostname', 'tag'
    # @option params [Integer] :limit Number of results to return (default: 500)
    # @option params [Integer] :offset Number of results to skip (default: 0)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :language Filter by language
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Website metrics with x (value) and y (visitor count)
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/metrics
    def website_metrics(website_id, params = {})
      get("/api/websites/#{website_id}/metrics", params)
    end

    # Get expanded website metrics with detailed engagement data
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :type Metrics type (required): 'path', 'entry', 'exit', 'title', 'query', 'referrer', 'channel', 'domain', 'country', 'region', 'city', 'browser', 'os', 'device', 'language', 'screen', 'event', 'hostname', 'tag'
    # @option params [Integer] :limit Number of results to return (default: 500)
    # @option params [Integer] :offset Number of results to skip (default: 0)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :language Filter by language
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Expanded metrics with name, pageviews, visitors, visits, bounces, totaltime
    # @see https://umami.is/docs/api/website-stats#get-/api/websites/:websiteid/metrics/expanded
    def website_metrics_expanded(website_id, params = {})
      get("/api/websites/#{website_id}/metrics/expanded", params)
    end

    # -------- Sessions endpoints --------

    # Get website sessions within a time range
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page (default: 20)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Hash] Paginated list of sessions
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/sessions
    def website_sessions(website_id, params = {})
      get("/api/websites/#{website_id}/sessions", params)
    end

    # Get summarized session statistics
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Hash] Session statistics including pageviews, visitors, visits, countries, events
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/sessions/stats
    def website_sessions_stats(website_id, params = {})
      get("/api/websites/#{website_id}/sessions/stats", params)
    end

    # Get session counts by hour of weekday
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :timezone Timezone (e.g., 'America/Los_Angeles') (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Array>] 7x24 matrix of session counts by weekday and hour
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/sessions/weekly
    def website_sessions_weekly(website_id, params = {})
      get("/api/websites/#{website_id}/sessions/weekly", params)
    end

    # Get details for an individual session
    #
    # @param website_id [String] The website's ID
    # @param session_id [String] The session's ID
    # @return [Hash] Session details including browser, os, device, visits, views, events, totaltime
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/sessions/:sessionid
    def website_session(website_id, session_id)
      get("/api/websites/#{website_id}/sessions/#{session_id}")
    end

    # Get activity for an individual session
    #
    # @param website_id [String] The website's ID
    # @param session_id [String] The session's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @return [Array<Hash>] Session activity records
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/sessions/:sessionid/activity
    def website_session_activity(website_id, session_id, params = {})
      get("/api/websites/#{website_id}/sessions/#{session_id}/activity", params)
    end

    # Get properties for an individual session
    #
    # @param website_id [String] The website's ID
    # @param session_id [String] The session's ID
    # @return [Array<Hash>] Session properties
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/sessions/:sessionid/properties
    def website_session_properties(website_id, session_id)
      get("/api/websites/#{website_id}/sessions/#{session_id}/properties")
    end

    # Get session data property counts
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Property aggregations with propertyName and total
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/session-data/properties
    def website_session_data_properties(website_id, params = {})
      get("/api/websites/#{website_id}/session-data/properties", params)
    end

    # Get session data value counts for a property
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :propertyName Property name to query (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Value aggregations with value and total
    # @see https://umami.is/docs/api/sessions#get-/api/websites/:websiteid/session-data/values
    def website_session_data_values(website_id, params = {})
      get("/api/websites/#{website_id}/session-data/values", params)
    end

    # -------- Events endpoints --------

    # Get website event details within a time range (paginated list)
    #
    # This method returns a paginated list of individual events with full details
    # and supports search and filtering. For time-series grouped event data,
    # use {#website_events} or {#website_events_series} instead.
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page (default: 20)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Hash] Paginated list of events with full event details
    # @see #website_events For time-series grouped event data
    # @see #website_events_series For event series with x/t/y format
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/events
    def website_events_list(website_id, params = {})
      get("/api/websites/#{website_id}/events", params)
    end

    # Get event data for an individual event
    #
    # @param website_id [String] The website's ID
    # @param event_id [String] The event's ID
    # @return [Array<Hash>] Event data properties
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/event-data/:eventid
    def website_event_data(website_id, event_id)
      get("/api/websites/#{website_id}/event-data/#{event_id}")
    end

    # Get event data names, properties, and counts
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :event Event name filter
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Event data with eventName, propertyName, dataType, total
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/event-data/events
    def website_event_data_events(website_id, params = {})
      get("/api/websites/#{website_id}/event-data/events", params)
    end

    # Get event data fields within a time range
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Event data fields with propertyName, dataType, value, total
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/event-data/fields
    def website_event_data_fields(website_id, params = {})
      get("/api/websites/#{website_id}/event-data/fields", params)
    end

    # Get event name and property counts
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Event properties with eventName, propertyName, total
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/event-data/properties
    def website_event_data_properties(website_id, params = {})
      get("/api/websites/#{website_id}/event-data/properties", params)
    end

    # Get event data value counts for a given event and property
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :event Event name (required)
    # @option params [String] :propertyName Property name (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Value counts with value and total
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/event-data/values
    def website_event_data_values(website_id, params = {})
      get("/api/websites/#{website_id}/event-data/values", params)
    end

    # Get aggregated event statistics
    #
    # @param website_id [String] The website's ID
    # @param params [Hash] Query parameters
    # @option params [Integer] :startAt Timestamp (in ms) of starting date (required)
    # @option params [Integer] :endAt Timestamp (in ms) of end date (required)
    # @option params [String] :path Filter by URL path
    # @option params [String] :referrer Filter by referrer
    # @option params [String] :title Filter by page title
    # @option params [String] :query Filter by query string
    # @option params [String] :os Filter by operating system
    # @option params [String] :browser Filter by browser
    # @option params [String] :device Filter by device type
    # @option params [String] :country Filter by country
    # @option params [String] :region Filter by region/state/province
    # @option params [String] :city Filter by city
    # @option params [String] :hostname Filter by hostname
    # @option params [String] :tag Filter by tag
    # @option params [String] :segment Filter by segment UUID
    # @option params [String] :cohort Filter by cohort UUID
    # @return [Array<Hash>] Event stats with events, properties, records counts
    # @see https://umami.is/docs/api/events#get-/api/websites/:websiteid/event-data/stats
    def website_event_data_stats(website_id, params = {})
      get("/api/websites/#{website_id}/event-data/stats", params)
    end

    # -------- Deprecated event data methods --------

    # @deprecated Use {#website_event_data_events} instead
    def event_data_events(website_id, params = {})
      warn "[DEPRECATION] `event_data_events` is deprecated. Use `website_event_data_events` instead."
      website_event_data_events(website_id, params)
    end

    # @deprecated Use {#website_event_data_fields} instead
    def event_data_fields(website_id, params = {})
      warn "[DEPRECATION] `event_data_fields` is deprecated. Use `website_event_data_fields` instead."
      website_event_data_fields(website_id, params)
    end

    # @deprecated Use {#website_event_data_stats} instead
    def event_data_stats(website_id, params = {})
      warn "[DEPRECATION] `event_data_stats` is deprecated. Use `website_event_data_stats` instead."
      website_event_data_stats(website_id, params)
    end

    # -------- Realtime endpoints --------

    # Get realtime stats for a website (last 30 minutes)
    #
    # @param website_id [String] The website's ID
    # @return [Hash] Realtime data including countries, urls, referrers, events, series, totals
    # @see https://umami.is/docs/api/realtime#get-/api/realtime/:websiteid
    def realtime(website_id)
      get("/api/realtime/#{website_id}")
    end

    # -------- Links endpoints --------

    # Get all links
    #
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of links
    # @see https://umami.is/docs/api/links#get-/api/links
    def links(params = {})
      get("/api/links", params)
    end

    # Get a link by ID
    #
    # @param link_id [String] The link's ID
    # @return [Hash] Link details
    # @see https://umami.is/docs/api/links#get-/api/links/:linkid
    def link(link_id)
      get("/api/links/#{link_id}")
    end

    # Update a link
    #
    # @param link_id [String] The link's ID
    # @param params [Hash] Link parameters to update
    # @option params [String] :name Link name
    # @option params [String] :url Destination URL
    # @option params [String] :slug URL slug (minimum 8 characters)
    # @return [Hash] Updated link details
    # @see https://umami.is/docs/api/links#post-/api/links/:linkid
    def update_link(link_id, params = {})
      post("/api/links/#{link_id}", params)
    end

    # Delete a link
    #
    # @param link_id [String] The link's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/links#delete-/api/links/:linkid
    def delete_link(link_id)
      delete("/api/links/#{link_id}")
    end

    # -------- Pixels endpoints --------

    # Get all pixels
    #
    # @param params [Hash] Query parameters
    # @option params [String] :search Search text
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of pixels
    # @see https://umami.is/docs/api/pixels#get-/api/pixels
    def pixels(params = {})
      get("/api/pixels", params)
    end

    # Get a pixel by ID
    #
    # @param pixel_id [String] The pixel's ID
    # @return [Hash] Pixel details
    # @see https://umami.is/docs/api/pixels#get-/api/pixels/:pixelid
    def pixel(pixel_id)
      get("/api/pixels/#{pixel_id}")
    end

    # Update a pixel
    #
    # @param pixel_id [String] The pixel's ID
    # @param params [Hash] Pixel parameters to update
    # @option params [String] :name Pixel name
    # @option params [String] :slug URL slug (minimum 8 characters)
    # @return [Hash] Updated pixel details
    # @see https://umami.is/docs/api/pixels#post-/api/pixels/:pixelid
    def update_pixel(pixel_id, params = {})
      post("/api/pixels/#{pixel_id}", params)
    end

    # Delete a pixel
    #
    # @param pixel_id [String] The pixel's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/pixels#delete-/api/pixels/:pixelid
    def delete_pixel(pixel_id)
      delete("/api/pixels/#{pixel_id}")
    end

    # -------- Reports endpoints --------

    # Get all reports
    #
    # @param params [Hash] Query parameters
    # @option params [String] :websiteId Website ID to filter by
    # @option params [String] :type Report type to filter by ('attribution', 'breakdown', 'funnel', 'goal', 'journey', 'retention', 'revenue', 'utm')
    # @option params [Integer] :page Page number (default: 1)
    # @option params [Integer] :pageSize Number of results per page
    # @return [Hash] Paginated list of reports
    # @see https://umami.is/docs/api/reports#get-/api/reports
    def reports(params = {})
      get("/api/reports", params)
    end

    # Create a new report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :type Report type (required)
    # @option params [String] :name Report name (required)
    # @option params [String] :description Report description
    # @option params [Hash] :parameters Report-specific parameters
    # @return [Hash] Created report details
    # @see https://umami.is/docs/api/reports#post-/api/reports
    def create_report(params = {})
      post("/api/reports", params)
    end

    # Get a report by ID
    #
    # @param report_id [String] The report's ID
    # @return [Hash] Report details
    # @see https://umami.is/docs/api/reports#get-/api/reports/:reportid
    def report(report_id)
      get("/api/reports/#{report_id}")
    end

    # Update a report
    #
    # @param report_id [String] The report's ID
    # @param params [Hash] Report parameters to update
    # @option params [String] :name Report name
    # @option params [String] :description Report description
    # @option params [Hash] :parameters Report-specific parameters
    # @return [Hash] Updated report details
    # @see https://umami.is/docs/api/reports#post-/api/reports/:reportid
    def update_report(report_id, params = {})
      post("/api/reports/#{report_id}", params)
    end

    # Delete a report
    #
    # @param report_id [String] The report's ID
    # @return [Hash] Confirmation message
    # @see https://umami.is/docs/api/reports#delete-/api/reports/:reportid
    def delete_report(report_id)
      delete("/api/reports/#{report_id}")
    end

    # Run an attribution report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [String] :model Attribution model ('firstClick' or 'lastClick')
    # @option params [String] :type Attribution type ('path' or 'event')
    # @option params [Integer] :step Step number
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Attribution report data
    # @see https://umami.is/docs/api/reports#post-/api/reports/attribution
    def report_attribution(params = {})
      post("/api/reports/attribution", params)
    end

    # Run a breakdown report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [Array<String>] :fields Fields to break down by (path, title, query, referrer, browser, os, device, country, region, city, hostname, tag, event)
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Breakdown report data
    # @see https://umami.is/docs/api/reports#post-/api/reports/breakdown
    def report_breakdown(params = {})
      post("/api/reports/breakdown", params)
    end

    # Run a funnel report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [Array<Hash>] :steps Funnel steps (minimum 2, each with type and value)
    # @option params [Integer] :window Number of days between steps
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Funnel report data with conversion and drop-off rates
    # @see https://umami.is/docs/api/reports#post-/api/reports/funnel
    def report_funnel(params = {})
      post("/api/reports/funnel", params)
    end

    # Run a goals report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [String] :type Goal type ('path' or 'event')
    # @option params [String] :value Goal value
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Goals report data
    # @see https://umami.is/docs/api/reports#post-/api/reports/goals
    def report_goals(params = {})
      post("/api/reports/goals", params)
    end

    # Run a journey report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [Integer] :steps Number of steps (3-7)
    # @option params [String] :startStep Starting step path
    # @option params [String] :endStep Ending step path
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Journey report data showing user navigation paths
    # @see https://umami.is/docs/api/reports#post-/api/reports/journey
    def report_journey(params = {})
      post("/api/reports/journey", params)
    end

    # Run a retention report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [String] :timezone Timezone (e.g., 'America/Los_Angeles') (required)
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Retention report data with day-based return rates
    # @see https://umami.is/docs/api/reports#post-/api/reports/retention
    def report_retention(params = {})
      post("/api/reports/retention", params)
    end

    # Run a revenue report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [String] :timezone Timezone (e.g., 'America/Los_Angeles') (required)
    # @option params [String] :currency ISO 4217 currency code
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] Revenue report data
    # @see https://umami.is/docs/api/reports#post-/api/reports/revenue
    def report_revenue(params = {})
      post("/api/reports/revenue", params)
    end

    # Run a UTM report
    #
    # @param params [Hash] Report parameters
    # @option params [String] :websiteId Website ID (required)
    # @option params [String] :startDate Start date in ISO 8601 format (required)
    # @option params [String] :endDate End date in ISO 8601 format (required)
    # @option params [Hash] :filters Filter criteria (path, referrer, title, query, browser, os, device, country, region, city, hostname, tag, segment, cohort)
    # @return [Hash] UTM report data with campaign parameter breakdown
    # @see https://umami.is/docs/api/reports#post-/api/reports/utm
    def report_utm(params = {})
      post("/api/reports/utm", params)
    end

    # -------- Sending stats endpoint --------

    # Send an event to Umami
    #
    # This method uses a separate connection that:
    # - Does NOT include Authorization header (not required for /api/send)
    # - Uses https://cloud.umami.is for Umami Cloud (different from the main API URL)
    # - Includes a User-Agent header (mandatory per API docs)
    #
    # @param payload [Hash] Event payload
    # @option payload [String] :hostname Name of host (required)
    # @option payload [String] :language Language of visitor (e.g., "en-US")
    # @option payload [String] :referrer Referrer URL
    # @option payload [String] :screen Screen resolution (e.g., "1920x1080")
    # @option payload [String] :title Page title
    # @option payload [String] :url Page URL (required)
    # @option payload [String] :website Website ID (required)
    # @option payload [String] :name Name of the event
    # @option payload [String] :tag Additional tag description
    # @option payload [String] :id Session identifier
    # @option payload [Hash] :data Additional data for the event
    # @param user_agent [String] Custom User-Agent header (defaults to "umami-ruby/VERSION")
    # @return [Hash] Response with cache, sessionId, and visitId
    # @note No authentication required. Uses https://cloud.umami.is for Umami Cloud.
    # @see https://umami.is/docs/api/sending-stats
    def send_event(payload, user_agent: default_user_agent)
      send_post("/api/send", { type: "event", payload: payload }, user_agent: user_agent)
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
      response.body == "ok" ? { "ok" => true } : JSON.parse(response.body)
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

    # -------- Send event helpers --------

    # Default User-Agent for send requests
    #
    # @return [String] User-Agent string identifying this gem
    def default_user_agent
      "umami-ruby/#{Umami::VERSION}"
    end

    # Determine the base URL for send requests
    #
    # For Umami Cloud, this returns https://cloud.umami.is (different from main API)
    # For self-hosted, this returns the configured uri_base
    #
    # @return [String] Base URL for send endpoint
    def send_uri_base
      cloud? ? Umami::Configuration::UMAMI_CLOUD_SEND_URL : @uri_base
    end

    # Separate connection for send endpoint
    #
    # This connection:
    # - Does NOT include Authorization header (not required for /api/send)
    # - Includes User-Agent header (mandatory per API docs)
    # - Not memoized because user_agent can vary per call
    #
    # @param user_agent [String] User-Agent header value
    # @return [Faraday::Connection] Connection for send requests
    def send_connection(user_agent:)
      Faraday.new(url: send_uri_base) do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
        faraday.headers["User-Agent"] = user_agent
        faraday.options.timeout = request_timeout
      end
    end

    # POST specifically for send endpoint (unauthenticated)
    #
    # @param path [String] API path
    # @param body [Hash] Request body
    # @param user_agent [String] User-Agent header value
    # @return [Hash] Parsed JSON response
    def send_post(path, body, user_agent:)
      response = send_connection(user_agent: user_agent).post(path, body.to_json)
      JSON.parse(response.body)
    rescue Faraday::Error => e
      handle_error(e)
    end

  end
end
