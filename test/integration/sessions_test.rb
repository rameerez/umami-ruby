# frozen_string_literal: true

require "test_helper"

class SessionsTest < Umami::TestCase
  def test_website_sessions_returns_paginated_list
    VCR.use_cassette("sessions/list") do
      client = configured_client
      result = client.website_sessions(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        pageSize: 5
      )

      assert_paginated_response(result)

      if result["data"].any?
        session = result["data"].first
        assert session.key?("id"), "Session should have 'id'"
        assert session.key?("browser") || session.key?("createdAt"), "Session should have browser or createdAt"
      end
    end
  end

  def test_website_sessions_stats
    VCR.use_cassette("sessions/stats") do
      client = configured_client
      result = client.website_sessions_stats(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms
      )

      assert_kind_of Hash, result

      # Should include aggregated stats
      %w[pageviews visitors visits countries events].each do |key|
        assert result.key?(key), "Session stats should include '#{key}'"
      end
    end
  end

  def test_website_sessions_weekly
    VCR.use_cassette("sessions/weekly") do
      client = configured_client
      result = client.website_sessions_weekly(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms,
        timezone: "UTC"
      )

      assert_kind_of Array, result

      # Should be a 7x24 matrix (7 days, 24 hours)
      if result.any?
        assert_kind_of Array, result.first, "Weekly data should be arrays of arrays"
      end
    end
  end

  def test_website_session_data_properties
    VCR.use_cassette("sessions/data_properties") do
      client = configured_client
      result = client.website_session_data_properties(test_website_id,
        startAt: thirty_days_ago_ms,
        endAt: now_ms
      )

      assert_kind_of Array, result

      if result.any?
        prop = result.first
        assert prop.key?("propertyName") || prop.key?("name"), "Property should have 'propertyName' or 'name'"
        assert prop.key?("total") || prop.key?("count"), "Property should have 'total' or 'count'"
      end
    end
  end
end
