# Umami Ruby

[![Gem Version](https://badge.fury.io/rb/umami-ruby.svg)](https://badge.fury.io/rb/umami-ruby)

A Ruby wrapper for the Umami analytics API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'umami-ruby'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install umami-ruby
```

## Documentation

Full API documentation is available [online](https://rameerez.github.io/umami-ruby/) or can be generated using YARD:

```bash
yard doc
yard server
```

## Usage

### Configuration

You can put this config in a handy location within your Rails project, like `config/initializers/umami.rb`

#### For self-hosted Umami instances:

```ruby
# With username and password
Umami.configure do |config|
  config.uri_base = "https://your-umami-instance.com"
  config.credentials = {
    username: "your_username",
    password: "your_password"
  }
end

# Or with an access token
Umami.configure do |config|
  config.uri_base = "https://your-umami-instance.com"
  config.access_token = "your_access_token"
end
```

#### For Umami Cloud:

```ruby
Umami.configure do |config|
  config.access_token = "your_api_key"
  # No need to specify uri_base for Umami Cloud
end
```

### Using the Client

After configuration, you can use the client to interact with the Umami API:

```ruby
client = Umami::Client.new

# Get all websites
websites = client.websites

# Get a specific website
website = client.website("website_id")

# Get website stats
stats = client.website_stats("website_id", { startAt: 1656679719687, endAt: 1656766119687 })

# Verify token
token_info = client.verify_token
```

## Error Handling

The gem defines several custom error classes:

- `Umami::ConfigurationError`: Raised for configuration-related issues.
- `Umami::AuthenticationError`: Raised for authentication-related issues.
- `Umami::APIError`: Raised for API request failures.

## Logging

The gem uses a logger that can be configured:

```ruby
Umami.logger.level = Logger::DEBUG
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rameerez/umami-ruby. Our code of conduct is: just be nice and make your mom proud of what you do and post online.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
