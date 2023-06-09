defmodule Ontogen.Commands.LogTest do
  use Ontogen.Local.Repo.Test.Case, async: false

  doctest Ontogen.Commands.Log

  describe "Repo.dataset_log/1" do
    test "on a clean repo without commits" do
      assert Repo.dataset_log() == {:ok, []}
    end

    test "full native history" do
      history = init_history()

      assert Repo.dataset_log() == {:ok, history}
    end

    test "full native history up to certain commit" do
      [fourth, third, second, first] = history = init_history()

      assert Repo.dataset_log(to_commit: first.__id__) == {:ok, Enum.slice(history, 0..2)}
      assert Repo.dataset_log(to_commit: second.__id__) == {:ok, Enum.slice(history, 0..1)}
      assert Repo.dataset_log(to_commit: third.__id__) == {:ok, Enum.slice(history, 0..0)}
      assert Repo.dataset_log(to_commit: fourth.__id__) == {:ok, []}
    end

    test "full native history from a certain commit" do
      [fourth, third, second, first] = history = init_history()

      assert Repo.dataset_log(from_commit: fourth.__id__) == {:ok, history}
      assert Repo.dataset_log(from_commit: third.__id__) == {:ok, Enum.slice(history, 1..3)}
      assert Repo.dataset_log(from_commit: second.__id__) == {:ok, Enum.slice(history, 2..3)}
      assert Repo.dataset_log(from_commit: first.__id__) == {:ok, Enum.slice(history, 3..3)}
    end

    test "full native history from a certain commit to a certain commit" do
      [fourth, third, second, first] = history = init_history()

      assert Repo.dataset_log(from_commit: fourth.__id__, to_commit: first.__id__) ==
               {:ok, Enum.slice(history, 0..2)}

      assert Repo.dataset_log(from_commit: third.__id__, to_commit: second.__id__) ==
               {:ok, Enum.slice(history, 1..1)}
    end

    test "when from_commit comes later than to_commit" do
      [fourth, third, second, first] = init_history()
      assert Repo.dataset_log(from_commit: second.__id__, to_commit: third.__id__) == {:ok, []}
      assert Repo.dataset_log(from_commit: first.__id__, to_commit: fourth.__id__) == {:ok, []}
    end

    test "full raw history" do
      history = init_history()

      assert Repo.dataset_log(type: :raw) ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
    end
  end

  defp init_history do
    init_commit_history([
      [
        insert: graph(),
        message: "Initial commit"
      ],
      [
        insert: {EX.S3, EX.p3(), "foo"},
        delete: EX.S1 |> EX.p1(EX.O1),
        committer: agent(:agent_jane),
        message: "Second commit"
      ],
      [
        insert: {EX.S4, EX.p4(), EX.O4},
        message: "Third commit"
      ],
      [
        insert: {EX.S5, EX.p5(), EX.O5},
        message: "Fourth commit"
      ]
    ])
  end
end
