# frozen_string_literal: true

require_relative "umami/version"
require_relative "umami/configuration"
require_relative "umami/client"
require_relative "umami/errors"
require "logger"

module Umami
  class << self
    attr_writer :configuration, :logger
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.logger
    @logger ||= Logger.new($stdout).tap do |log|
      log.progname = self.name
    end
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.client(options = {})
    Client.new(options)
  end
end
