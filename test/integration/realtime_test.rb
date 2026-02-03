# frozen_string_literal: true

require "test_helper"

class RealtimeTest < Umami::TestCase
  def test_realtime_returns_current_data
    VCR.use_cassette("realtime/current") do
      client = configured_client
      result = client.realtime(test_website_id)

      assert_kind_of Hash, result

      # Realtime data should include various components
      %w[countries urls referrers events totals].each do |key|
        assert result.key?(key), "Realtime data should include '#{key}'"
      end

      # Check totals structure
      totals = result["totals"]
      assert_kind_of Hash, totals
      assert totals.key?("visitors") || totals.key?("pageviews"),
        "Totals should include visitor or pageview counts"
    end
  end
end
