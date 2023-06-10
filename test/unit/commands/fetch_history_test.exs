defmodule Ontogen.Commands.FetchHistoryTest do
  use Ontogen.Local.Repo.Test.Case, async: false

  doctest Ontogen.Commands.FetchHistory

  describe "Repo.dataset_history/1" do
    test "on a clean repo without commits" do
      assert Repo.dataset_history() == {:error, :no_head}
    end

    test "full native history" do
      history = init_history()

      assert Repo.dataset_history() == {:ok, history}
    end

    test "full native history up to certain commit" do
      [fourth, third, second, first] = history = init_history()

      assert Repo.dataset_history(to_commit: first.__id__) == {:ok, Enum.slice(history, 0..2)}
      assert Repo.dataset_history(to_commit: second.__id__) == {:ok, Enum.slice(history, 0..1)}
      assert Repo.dataset_history(to_commit: third.__id__) == {:ok, Enum.slice(history, 0..0)}
      assert Repo.dataset_history(to_commit: fourth.__id__) == {:ok, []}
    end

    test "full native history from a certain commit" do
      [fourth, third, second, first] = history = init_history()

      assert Repo.dataset_history(from_commit: fourth.__id__) == {:ok, history}
      assert Repo.dataset_history(from_commit: third.__id__) == {:ok, Enum.slice(history, 1..3)}
      assert Repo.dataset_history(from_commit: second.__id__) == {:ok, Enum.slice(history, 2..3)}
      assert Repo.dataset_history(from_commit: first.__id__) == {:ok, Enum.slice(history, 3..3)}
    end

    test "full native history from a certain commit to a certain commit" do
      [fourth, third, second, first] = history = init_history()

      assert Repo.dataset_history(from_commit: fourth.__id__, to_commit: first.__id__) ==
               {:ok, Enum.slice(history, 0..2)}

      assert Repo.dataset_history(from_commit: third.__id__, to_commit: second.__id__) ==
               {:ok, Enum.slice(history, 1..1)}
    end

    test "when from_commit comes later than to_commit" do
      [fourth, third, second, first] = init_history()

      assert Repo.dataset_history(from_commit: second.__id__, to_commit: third.__id__) ==
               {:ok, []}

      assert Repo.dataset_history(from_commit: first.__id__, to_commit: fourth.__id__) ==
               {:ok, []}
    end

    test "full raw history" do
      history = init_history()

      assert Repo.dataset_history(type: :raw) ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
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

  describe "Repo.resource_history/1" do
    test "on a clean repo without commits" do
      assert Repo.resource_history(EX.S1) == {:error, :no_head}
    end

    test "full native history" do
      history = init_resource_history()

      assert Repo.resource_history(EX.S1) == {:ok, history}
    end

    test "full native history up to certain commit" do
      [fourth, third, second, first] = history = init_resource_history()

      assert Repo.resource_history(EX.S1, to_commit: first.__id__) ==
               {:ok, Enum.slice(history, 0..2)}

      assert Repo.resource_history(EX.S1, to_commit: second.__id__) ==
               {:ok, Enum.slice(history, 0..1)}

      assert Repo.resource_history(EX.S1, to_commit: third.__id__) ==
               {:ok, Enum.slice(history, 0..0)}

      assert Repo.resource_history(EX.S1, to_commit: fourth.__id__) == {:ok, []}
    end

    test "full native history from a certain commit" do
      [fourth, third, second, first] = history = init_resource_history()

      assert Repo.resource_history(EX.S1, from_commit: fourth.__id__) == {:ok, history}

      assert Repo.resource_history(EX.S1, from_commit: third.__id__) ==
               {:ok, Enum.slice(history, 1..3)}

      assert Repo.resource_history(EX.S1, from_commit: second.__id__) ==
               {:ok, Enum.slice(history, 2..3)}

      assert Repo.resource_history(EX.S1, from_commit: first.__id__) ==
               {:ok, Enum.slice(history, 3..3)}
    end

    test "full native history from a certain commit to a certain commit" do
      [fourth, third, second, first] = history = init_resource_history()

      assert Repo.resource_history(EX.S1, from_commit: fourth.__id__, to_commit: first.__id__) ==
               {:ok, Enum.slice(history, 0..2)}

      assert Repo.resource_history(EX.S1, from_commit: third.__id__, to_commit: second.__id__) ==
               {:ok, Enum.slice(history, 1..1)}
    end

    test "when from_commit comes later than to_commit" do
      [fourth, third, second, first] = init_resource_history()

      assert Repo.resource_history(EX.S1, from_commit: second.__id__, to_commit: third.__id__) ==
               {:ok, []}

      assert Repo.resource_history(EX.S1, from_commit: first.__id__, to_commit: fourth.__id__) ==
               {:ok, []}
    end

    test "full raw history" do
      history = init_resource_history()

      assert Repo.resource_history(EX.S1, type: :raw) ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
    end

    defp init_resource_history do
      [fourth, _, _, third, second, _, first] =
        init_commit_history([
          [
            insert: graph(),
            message: "Initial commit"
          ],
          [
            insert: {EX.S3, EX.p3(), "foo"},
            message: "Irrelevant commit"
          ],
          [
            insert: {EX.S3, EX.p3(), "bar"},
            delete: EX.S1 |> EX.p1(EX.O1),
            committer: agent(:agent_jane),
            message: "Second commit"
          ],
          [
            insert: {EX.S1, EX.p4(), EX.O4},
            message: "Third commit"
          ],
          [
            insert: [{EX.S1, EX.p4(), EX.O4}, {EX.S4, EX.p4(), EX.O4}],
            message: "Irrelevant effective commit"
          ],
          [
            insert: {EX.S5, EX.p2(), EX.O2},
            message: "Another irrelevant commit"
          ],
          [
            insert: [{EX.S1, EX.p2(), EX.O2}, {EX.S2, EX.p2(), EX.O2}],
            message: "Fourth commit"
          ]
        ])

      [fourth, third, second, first]
    end
  end
end
