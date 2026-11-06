# frozen_string_literal: true

require "test_helper"

class PageviewsOverRangeTest < Umami::TestCase
  DAY = 24 * 60 * 60 * 1000

  def setup
    super
    @client = Umami::Client.new(uri_base: "https://umami.example", access_token: "token")
    @path = "https://umami.example/api/websites/site/pageviews"
  end

  def stub_window(from, to, pageviews:, sessions:)
    stub_request(:get, @path)
      .with(query: hash_including("startAt" => from.to_s, "endAt" => to.to_s, "unit" => "day"))
      .to_return(body: { pageviews: pageviews, sessions: sessions }.to_json)
  end

  def test_a_year_of_days_is_asked_for_in_pieces_and_joined
    start = Time.utc(2025, 11, 1).to_i * 1000
    finish = start + 200 * DAY - 1
    stub_window(start, start + 90 * DAY - 1, pageviews: [{ x: "2025-11-01", y: 5 }], sessions: [{ x: "2025-11-01", y: 2 }])
    stub_window(start + 90 * DAY, start + 180 * DAY - 1, pageviews: [{ x: "2026-01-30", y: 7 }], sessions: [])
    stub_window(start + 180 * DAY, finish, pageviews: [{ x: "2026-04-30", y: 1 }], sessions: [{ x: "2026-04-30", y: 1 }])

    result = @client.website_pageviews_over_range("site", startAt: start, endAt: finish, unit: "day", timezone: "UTC")

    assert_equal %w[2025-11-01 2026-01-30 2026-04-30], result["pageviews"].map { |point| point["x"] }
    assert_equal [5, 7, 1], result["pageviews"].map { |point| point["y"] }
    assert_equal [{ "x" => "2025-11-01", "y" => 2 }, { "x" => "2026-04-30", "y" => 1 }], result["sessions"]
    assert_requested :get, @path, query: hash_including("timezone" => "UTC"), times: 3
  end

  def test_a_bucket_split_across_two_requests_is_added_up
    start = 0
    stub_window(0, 90 * DAY - 1, pageviews: [{ x: "day-90", y: 3 }], sessions: [])
    stub_window(90 * DAY, 91 * DAY, pageviews: [{ x: "day-90", y: 4 }], sessions: [])

    result = @client.website_pageviews_over_range("site", startAt: start, endAt: 91 * DAY, unit: "day")

    assert_equal [{ "x" => "day-90", "y" => 7 }], result["pageviews"]
  end

  def test_a_short_range_is_one_plain_request
    stub_window(0, 7 * DAY, pageviews: [], sessions: [])

    @client.website_pageviews_over_range("site", "startAt" => 0, "endAt" => 7 * DAY, "unit" => "day")

    assert_requested :get, @path, query: hash_including({}), times: 1
  end

  def test_units_umami_never_coarsens_are_passed_straight_through
    stub_request(:get, @path).with(query: hash_including("unit" => "month"))
      .to_return(body: { pageviews: [], sessions: [] }.to_json)

    @client.website_pageviews_over_range("site", startAt: 0, endAt: 1000 * DAY, unit: "month")

    assert_requested :get, @path, query: hash_including({}), times: 1
  end
end
