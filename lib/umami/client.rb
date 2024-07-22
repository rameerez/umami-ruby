require "faraday"
require "json"

module Umami
  class Client
    attr_reader :access_token, :uri_base, :request_timeout

    def initialize(access_token: nil, uri_base: nil, request_timeout: nil)
      @access_token = access_token || Umami.configuration.access_token
      @uri_base = uri_base || Umami.configuration.uri_base
      @request_timeout = request_timeout || Umami.configuration.request_timeout

      raise Umami::Error, "Access token is required" if @access_token.nil?
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

    private

    def get(path, params = {})
      response = connection.get(path, params)
      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise Umami::Error, "API request failed: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new(url: uri_base) do |faraday|
        faraday.request :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
        faraday.headers["Authorization"] = "Bearer #{access_token}"
        faraday.options.timeout = request_timeout
      end
    end
  end
end
