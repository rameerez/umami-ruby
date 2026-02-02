# frozen_string_literal: true

require "test_helper"

class StatsTest < Umami::TestCase
  def test_website_stats_returns_statistics
    VCR.use_cassette("stats/website_stats") do
      client = configured_client
      result = client.website_stats(test_website_id,
        startAt: seven_days_ago_ms,
        endAt: now_ms
      )

      assert_kind_of Hash, result

      # Stats should include these keys (values may be nested)
      %w[pageviews visitors visits bounces totaltime].each do |key|
        assert result.key?(key), "Expected stats to include '#{key}'"
      end
    end
  end

  def test_website_active_visitors
    VCR.use_cassette("stats/active_visitors") do
      client = configured_client
      result = client.website_active_visitors(test_website_id)

      assert_kind_of Hash, result
      # API may return "x" or "visitors" depending on version
      assert result.key?("x") || result.key?("visitors"),
        "Active visitors response should have 'x' or 'visitors' key"
    end
  end

  def test_website_pageviews_daily
    VCR.use_cassette("stats/pageviews_daily") do
      client = configured_client
      result = client.website_pageviews(test_website_id,
        startAt: seven_days_ago_ms,
        endAt: now_ms,
        unit: "day"
      )

      assert_kind_of Hash, result
      assert result.key?("pageviews")
      assert result.key?("sessions")
      assert_kind_of Array, result["pageviews"]
      assert_kind_of Array, result["sessions"]

      # Verify structure of data points
      if result["pageviews"].any?
        data_point = result["pageviews"].first
        assert data_point.key?("x"), "Pageview data point should have 'x' (timestamp)"
        assert data_point.key?("y"), "Pageview data point should have 'y' (count)"
      end
    end
  end

  def test_website_pageviews_hourly
    VCR.use_cassette("stats/pageviews_hourly") do
      client = configured_client
      result = client.website_pageviews(test_website_id,
        startAt: seven_days_ago_ms,
        endAt: now_ms,
        unit: "hour"
      )

      assert_kind_of Hash, result
      assert result.key?("pageviews")
      assert result.key?("sessions")
    end
  end
end
