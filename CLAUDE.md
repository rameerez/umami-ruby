# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`umami-ruby` is a Ruby wrapper for the Umami Analytics API. It works with both Umami Cloud and self-hosted instances.

## Key Files

- `lib/umami/client.rb` - Main API client with all endpoint methods
- `lib/umami/configuration.rb` - Configuration management
- `lib/umami/errors.rb` - Custom error classes
- `test/` - Minitest test suite with VCR cassettes

## Development Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run tests with coverage
bundle exec rake test  # SimpleCov runs automatically

# Generate documentation
yard doc
yard server
```

## Testing Guidelines

- All tests use VCR cassettes for HTTP interactions
- Cassettes are in `test/cassettes/`
- Use `VCR_RECORD_MODE=new_episodes bundle exec rake test` to record new cassettes
- Anonymize all sensitive data in cassettes before committing

## Code Style

- Follow standard Ruby conventions
- Use YARD documentation for all public methods
- Keep methods focused and single-purpose
- Error handling uses custom error classes inheriting from `Umami::Error`
