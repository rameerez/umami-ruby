# frozen_string_literal: true

require_relative "umami/version"
require_relative "umami/configuration"
require_relative "umami/client"

module Umami
  class Error < StandardError; end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset
    @configuration = Configuration.new
  end
end
