defmodule Ontogen.Commit.Range.FetcherTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Commit.Range.Fetcher

  alias Ontogen.Commit.Range.Fetcher
  alias Ontogen.{Commit, InvalidCommitRangeError}

  describe "fetch/3" do
    test "on a clean repo without commits", %{repo: repo, store: store} do
      assert Fetcher.fetch(:head, store, repo) == {:error, :no_head}
    end

    test "with commit in history", %{store: store} do
      [fourth, third, second, first] = history = init_history()

      assert Fetcher.fetch(:head, store, Ontogen.repository()) == {:ok, history}
      assert Fetcher.fetch(fourth, store, Ontogen.repository()) == {:ok, history}

      assert Fetcher.fetch(third, store, Ontogen.repository()) ==
               {:ok, Enum.slice(history, 1..3)}

      assert Fetcher.fetch(second, store, Ontogen.repository()) ==
               {:ok, Enum.slice(history, 2..3)}

      assert Fetcher.fetch(first, store, Ontogen.repository()) ==
               {:ok, Enum.slice(history, 3..3)}
    end

    test "with independent commit", %{store: store} do
      init_history()
      independent_commit = commit()

      assert Fetcher.fetch(independent_commit, store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end
  end

  describe "Commit.Range.fetch/3" do
    test "relative base out of range", %{store: store} do
      init_history()

      assert Commit.Range.new!(base: 99) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "with commit range in history", %{store: store} do
      [fourth, third, second, first] = history = init_history()

      assert Commit.Range.new!(base: first) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, fourth, Enum.slice(history, 0..2))

      assert Commit.Range.new!(base: third) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(third, fourth, Enum.slice(history, 0..0))

      assert Commit.Range.new!(base: fourth) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(fourth, fourth, [])

      assert Commit.Range.new!(target: fourth)
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), fourth, history)

      assert Commit.Range.new!(target: first) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), first, Enum.slice(history, 3..3))

      assert Commit.Range.new!(base: first, target: fourth)
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, fourth, Enum.slice(history, 0..2))

      assert Commit.Range.new!(base: second, target: third)
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(second, third, Enum.slice(history, 1..1))

      assert Commit.Range.new!(range: {second, third})
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(second, third, Enum.slice(history, 1..1))

      assert Commit.Range.new!(base: 1) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(third, fourth, Enum.slice(history, 0..0))

      assert Commit.Range.new!(base: 4) |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), fourth, history)

      assert Commit.Range.new!(target: third, base: 2)
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, third, Enum.slice(history, 1..2))

      assert Commit.Range.new!(target: first, base: 1)
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), first, Enum.slice(history, 3..3))
    end

    test "with commit range with refs in history", %{store: store} do
      [fourth, third, second, first] = history = init_history()

      assert Commit.Range.parse!("#{first}..head~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, third, Enum.slice(history, 1..2))

      assert Commit.Range.parse!("#{first}..#{third}~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, second, Enum.slice(history, 2..2))

      assert Commit.Range.parse!("head~3..head~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, third, Enum.slice(history, 1..2))

      assert Commit.Range.parse!("#{second}~1..head~2")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, second, Enum.slice(history, 2..2))

      assert Commit.Range.parse!("#{fourth}~3..#{third}~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, second, Enum.slice(history, 2..2))

      assert Commit.Range.parse!("#{fourth}~3..#{second}")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(first, second, Enum.slice(history, 2..2))

      assert Commit.Range.new!(base: 1, target: Commit.Ref.new!(:head, 1))
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(second, third, Enum.slice(history, 1..1))
    end

    test "base refs of the commit root", %{store: store} do
      [fourth, third, _second, first] = history = init_history()

      assert Commit.Range.parse!("#{first}~1..head~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), third, Enum.slice(history, 1..3))

      assert Commit.Range.parse!("#{fourth}~4..head~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), third, Enum.slice(history, 1..3))

      assert Commit.Range.parse!("head~4..head~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               ok_range(Commit.root(), third, Enum.slice(history, 1..3))
    end

    test "commit refs out of range", %{store: store} do
      [_fourth, _third, second, first] = init_history()

      assert Commit.Range.parse!("#{second}~3..head~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Commit.Range.parse!("head~5..head~3")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Commit.Range.parse!("#{first}..head~5")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Commit.Range.parse!("#{first}..#{first}~2")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Commit.Range.parse!("#{first}..#{first}~1")
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "with independent commits in commit range", %{store: store} do
      [fourth, _third, _second, first] = init_history()
      independent_commit = commit()

      assert Commit.Range.new!(range: {first, independent_commit})
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Commit.Range.new!(range: {independent_commit, fourth})
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "when the specified target commit comes later than the base commit", %{store: store} do
      [fourth, _third, _second, first] = init_history()

      assert Commit.Range.new!(base: fourth, target: first)
             |> Commit.Range.fetch(store, Ontogen.repository()) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end
  end

  defp ok_range(base, target, commit_ids) do
    {:ok, %Commit.Range{commit_ids: commit_ids, base: base, target: target}}
  end

  defp init_history do
    graph = [
      EX.S1 |> EX.p1(EX.O1),
      EX.S2 |> EX.p2(42, "Foo")
    ]

    init_commit_history([
      [
        add: graph,
        message: "Initial commit"
      ],
      [
        # this leads to a different effective change
        add: [{EX.S3, EX.p3(), "foo"}],
        remove: EX.S1 |> EX.p1(EX.O1),
        committer: agent(:agent_jane),
        message: "Second commit"
      ],
      [
        # this leads to a different effective change
        add: [{EX.S4, EX.p4(), EX.O4}, {EX.S3, EX.p3(), "foo"}],
        message: "Third commit",
        committer: id(:agent_john)
      ],
      [
        # this leads to a different effective change
        update: [{EX.S5, EX.p5(), EX.O5}, graph],
        message: "Fourth commit"
      ]
    ])
    |> Enum.map(& &1.__id__)
  end
end
