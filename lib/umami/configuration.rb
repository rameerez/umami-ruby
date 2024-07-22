module Umami
  class Configuration
    attr_accessor :access_token, :uri_base, :request_timeout

    def initialize
      @access_token = nil
      @uri_base = "https://api.umami.is"
      @request_timeout = 120
    end
  end
end
