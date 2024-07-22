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

## Usage

First, configure the gem with your Umami API credentials:

```ruby
Umami.configure do |config|
  config.access_token = "your_umami_access_token"
end
```

Then, you can use the client to interact with the Umami API:

```ruby
client = Umami::Client.new

# Get all websites
websites = client.websites

# Get a specific website
website = client.website("website_id")

# Get website stats
stats = client.website_stats("website_id", { startAt: 1656679719687, endAt: 1656766119687 })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rameerez/umami-ruby. Our code of conduct is: just be nice and make your mom proud of what you do and post online.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
