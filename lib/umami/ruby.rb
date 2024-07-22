# frozen_string_literal: true

require_relative "ruby/version"
require_relative "client"

module Umami
  module Ruby
    class Error < StandardError; end

    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :access_token, :uri_base, :request_timeout

      def initialize
        @access_token = nil
        @uri_base = "https://api.umami.is"
        @request_timeout = 120
      end
    end

  end
end
