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

  test "parse_time/1" do
    test_cases = [
      {"2023-04-15T14:30:00Z", ~U[2023-04-15 14:30:00Z]},
      {"20230415T143000Z", ~U[2023-04-15 14:30:00Z]},
      {"2023-04-15T14:30:00+00:00", ~U[2023-04-15 14:30:00Z]},
      {"2023-04-15", ~N[2023-04-15 00:00:00]},
      {"2023-4-5", ~N[2023-04-05 00:00:00]},
      {"2023-04-05", ~N[2023-04-05 00:00:00]},
      {"2023-04-15 14:30:00", ~N[2023-04-15 14:30:00]},
      {"15.04.2023", ~N[2023-04-15 00:00:00]},
      {"04/15/2023", ~N[2023-04-15 00:00:00]},
      {"2023/04/15", ~N[2023-04-15 00:00:00]},
      {"15 April 2023", ~N[2023-04-15 00:00:00]},
      {"15 Apr 2023", ~N[2023-04-15 00:00:00]},
      {"April 15, 2023", ~N[2023-04-15 00:00:00]},
      {"Saturday, 15 April 2023", ~N[2023-04-15 00:00:00]},
      {"14:30:00 15/04/2023", ~N[2023-04-15 14:30:00]},
      {"PM 02:30 15/04/2023", ~N[2023-04-15 14:30:00]}
    ]

    for {input, expected} <- test_cases do
      assert {:ok, result} = Utils.parse_time(input)
      assert result == expected, "Failed to parse: #{input}"
    end

    assert Utils.parse_time("invalid date") == {:error, "failed to parse invalid date"}
  end

  defp seconds_ago(seconds) do
    DateTime.add(DateTime.utc_now(), -seconds, :second)
  end
end
