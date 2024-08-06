defmodule Ontogen.UtilsTest do
  use ExUnit.Case

  doctest Ontogen.Utils

  alias Ontogen.Utils

  test "human_relative_time/1" do
    assert 0 |> seconds_ago() |> Utils.human_relative_time() == "now"
    assert 32 |> seconds_ago() |> Utils.human_relative_time() == "32 seconds ago"
    assert 60 |> seconds_ago() |> Utils.human_relative_time() == "1 minute ago"
    assert 234 |> seconds_ago() |> Utils.human_relative_time() == "3 minutes ago"
    assert 610 |> seconds_ago() |> Utils.human_relative_time() == "10 minutes ago"
    assert 3599 |> seconds_ago() |> Utils.human_relative_time() == "59 minutes ago"
    assert 3700 |> seconds_ago() |> Utils.human_relative_time() == "1 hour ago"
    assert 23700 |> seconds_ago() |> Utils.human_relative_time() == "6 hours ago"
    assert 86400 |> seconds_ago() |> Utils.human_relative_time() == "yesterday"
    assert 604_800 |> seconds_ago() |> Utils.human_relative_time() == "7 days ago"
    assert 2_629_746 |> seconds_ago() |> Utils.human_relative_time() == "1 month ago"
    assert 8_629_746 |> seconds_ago() |> Utils.human_relative_time() == "3 months ago"
    assert 31_556_926 |> seconds_ago() |> Utils.human_relative_time() == "1 year ago"
    assert 65_225_636 |> seconds_ago() |> Utils.human_relative_time() == "2 years ago"
  end

  defp seconds_ago(seconds) do
    DateTime.add(DateTime.utc_now(), -seconds, :second)
  end
end
