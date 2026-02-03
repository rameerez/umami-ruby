# frozen_string_literal: true

require "test_helper"

class MetricsTest < Umami::TestCase
  def test_website_metrics_path
    VCR.use_cassette("metrics/path") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "path",
        limit: 10
      )

      assert_kind_of Array, result

      if result.any?
        metric = result.first
        assert metric.key?("x"), "Metric should have 'x' (path value)"
        assert metric.key?("y"), "Metric should have 'y' (count)"
      end
    end
  end

  def test_website_metrics_referrer
    VCR.use_cassette("metrics/referrer") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "referrer",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_country
    VCR.use_cassette("metrics/country") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "country",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_browser
    VCR.use_cassette("metrics/browser") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "browser",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_os
    VCR.use_cassette("metrics/os") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "os",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_device
    VCR.use_cassette("metrics/device") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "device",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_language
    VCR.use_cassette("metrics/language") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "language",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_screen
    VCR.use_cassette("metrics/screen") do
      client = configured_client
      result = client.website_metrics(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "screen",
        limit: 10
      )

      assert_kind_of Array, result
    end
  end

  def test_website_metrics_expanded
    VCR.use_cassette("metrics/expanded_path") do
      client = configured_client
      result = client.website_metrics_expanded(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        type: "path",
        limit: 10
      )

      assert_kind_of Array, result

      # Expanded metrics should include additional engagement data
      if result.any?
        metric = result.first
        assert metric.key?("name") || metric.key?("x"), "Expanded metric should have 'name' or 'x'"
      end
    end
  end
end
