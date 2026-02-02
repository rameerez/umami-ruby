# frozen_string_literal: true

require "test_helper"

class EventsTest < Umami::TestCase
  def test_website_events
    VCR.use_cassette("events/list") do
      client = configured_client
      result = client.website_events(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms
      )

      # Can be either Array or Hash depending on Umami version
      assert [Array, Hash].include?(result.class), "Events should be Array or Hash"
    end
  end

  def test_website_events_list_paginated
    VCR.use_cassette("events/events_list_paginated") do
      client = configured_client
      result = client.website_events_list(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        pageSize: 5
      )

      # Should return paginated data or array
      if result.is_a?(Hash) && result.key?("data")
        assert_kind_of Array, result["data"]
      else
        assert_kind_of Array, result
      end
    end
  end

  def test_website_event_data_fields
    VCR.use_cassette("events/event_data_fields") do
      client = configured_client
      result = client.website_event_data_fields(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms
      )

      assert_kind_of Array, result
    end
  end

  def test_website_event_data_properties
    VCR.use_cassette("events/event_data_properties") do
      client = configured_client
      result = client.website_event_data_properties(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms
      )

      assert_kind_of Array, result
    end
  end

  def test_website_event_data_stats
    VCR.use_cassette("events/event_data_stats") do
      client = configured_client
      result = client.website_event_data_stats(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms
      )

      # Can return either Array or Hash depending on Umami version
      assert [Array, Hash].include?(result.class), "Event stats should be Array or Hash"

      if result.is_a?(Hash)
        # Stats hash should have count information
        assert result.key?("events") || result.key?("count") || result.key?("total"),
          "Event stats should have count information"
      elsif result.any?
        stat = result.first
        # Should have count information
        assert stat.key?("events") || stat.key?("count") || stat.key?("total"),
          "Event stats should have count information"
      end
    end
  end
end
