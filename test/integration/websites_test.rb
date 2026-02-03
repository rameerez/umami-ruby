# frozen_string_literal: true

require "test_helper"

class WebsitesTest < Umami::TestCase
  def test_websites_returns_paginated_list
    VCR.use_cassette("websites/list") do
      client = configured_client
      result = client.websites

      assert_paginated_response(result)

      # Verify website structure
      if result["data"].any?
        website = result["data"].first
        assert website.key?("id")
        assert website.key?("name")
        assert website.key?("domain")
        assert website.key?("createdAt")
      end
    end
  end

  def test_websites_accepts_pagination_params
    VCR.use_cassette("websites/list_paginated") do
      client = configured_client
      result = client.websites(page: 1, pageSize: 5)

      assert_paginated_response(result)
      assert result["data"].length <= 5
    end
  end

  def test_website_returns_single_website
    VCR.use_cassette("websites/get_single") do
      client = configured_client
      result = client.website(test_website_id)

      assert_kind_of Hash, result
      assert_equal test_website_id, result["id"]
      assert result.key?("name")
      assert result.key?("domain")
      assert result.key?("createdAt")
    end
  end

  def test_website_not_found_returns_null
    # Note: Umami API returns null with 200 status for non-existent websites,
    # rather than a 404 error. This is the documented API behavior.
    VCR.use_cassette("errors/not_found_website") do
      client = configured_client
      result = client.website("00000000-0000-0000-0000-000000000000")

      # API returns null (parsed as nil) for non-existent websites
      assert_nil result
    end
  end
end
