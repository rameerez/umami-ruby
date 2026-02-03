# frozen_string_literal: true

require_relative "lib/umami/version"

Gem::Specification.new do |spec|
  spec.name = "umami-ruby"
  spec.version = Umami::VERSION
  spec.authors = ["rameerez"]
  spec.email = ["umamiruby@rameerez.com"]

  spec.summary = "Ruby wrapper for the Umami API"
  spec.description = "A simple and efficient Ruby gem to interact with the Umami analytics API"
  spec.homepage = "https://github.com/rameerez/umami-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rameerez/umami-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/rameerez/umami-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rameerez.github.io/umami-ruby/"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
end
