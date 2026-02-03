# frozen_string_literal: true

require "test_helper"

class MeTest < Umami::TestCase
  def test_me_returns_current_user
    VCR.use_cassette("me/current_user") do
      client = configured_client
      result = client.me

      assert_kind_of Hash, result
      assert result.key?("token")
      assert result.key?("user")

      user = result["user"]
      assert user.key?("id")
      assert user.key?("username")
      assert user.key?("role")
      assert user.key?("createdAt")
    end
  end

  def test_my_teams_returns_teams_list
    VCR.use_cassette("me/my_teams") do
      client = configured_client
      result = client.my_teams

      assert_kind_of Hash, result
      assert result.key?("data")
      assert_kind_of Array, result["data"]
    end
  end

  def test_my_websites_returns_websites_list
    VCR.use_cassette("me/my_websites") do
      client = configured_client
      result = client.my_websites

      assert_kind_of Hash, result
      assert result.key?("data")
      assert_kind_of Array, result["data"]

      # Verify website structure if any exist
      if result["data"].any?
        website = result["data"].first
        assert website.key?("id")
        assert website.key?("name")
        assert website.key?("domain")
      end
    end
  end

  def test_my_websites_with_teams_option
    VCR.use_cassette("me/my_websites_with_teams") do
      client = configured_client
      result = client.my_websites(includeTeams: true)

      assert_kind_of Hash, result
      assert result.key?("data")
      assert_kind_of Array, result["data"]
    end
  end
end
