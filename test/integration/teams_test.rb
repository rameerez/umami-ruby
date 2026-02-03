# frozen_string_literal: true

require "test_helper"

class TeamsTest < Umami::TestCase
  def test_teams_returns_list
    VCR.use_cassette("teams/list") do
      client = configured_client
      result = client.teams

      assert_kind_of Hash, result
      assert result.key?("data")
      assert_kind_of Array, result["data"]

      if result["data"].any?
        team = result["data"].first
        assert team.key?("id"), "Team should have 'id'"
        assert team.key?("name"), "Team should have 'name'"
      end
    end
  end
end
