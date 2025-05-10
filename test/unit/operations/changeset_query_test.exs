defmodule Ontogen.Operations.ChangesetQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.ChangesetQuery

  alias Gno.EffectiveChangeset
  alias Ontogen.{InvalidCommitRangeError, EmptyRepositoryError}

  describe "Ontogen.changeset/1" do
    test "on a clean repo without commits" do
      assert Ontogen.changeset() ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "target commit (default)" do
      [target_commit | _] = init_history()

      assert Ontogen.changeset() == Ontogen.changeset(target: target_commit.__id__)
    end

    test "with a specified base commit" do
      [fourth, third, second, _first] = init_history()

      assert Ontogen.changeset!(base: second) ==
               merged([third, fourth])

      assert Ontogen.changeset!(base: fourth) == nil
    end

    test "with a specified target commit" do
      [fourth, _third, second, first] = history = init_history()

      assert Ontogen.changeset!(target: fourth.__id__) ==
               history |> Enum.reverse() |> merged()

      assert Ontogen.changeset!(target: second.__id__) ==
               merged([first, second])
    end

    test "with a specified base and target commit" do
      [fourth, third, second, first] = init_history()

      assert Ontogen.changeset!(base: first.__id__, target: fourth.__id__) ==
               merged([second, third, fourth])

      assert Ontogen.changeset!(base: second.__id__, target: third.__id__) ==
               EffectiveChangeset.new!(third)
    end

    test "with relative base commit" do
      [fourth, third, second, first] = history = init_history()

      assert Ontogen.changeset(base: 1) ==
               EffectiveChangeset.new(fourth)

      assert Ontogen.changeset!(base: 4) ==
               merged(Enum.reverse(history))

      assert Ontogen.changeset(target: third, base: 1) ==
               EffectiveChangeset.new(third)

      assert Ontogen.changeset!(target: second, base: 2) ==
               merged([second, first])
    end

    test "when the specified target commit comes later than the base commit" do
      [_fourth, third, second, _first] = init_history()

      assert Ontogen.changeset(base: third.__id__, target: second.__id__) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "parent commit chain is used for ordering" do
      graph = [
        EX.S1 |> EX.p1(EX.O1),
        EX.S2 |> EX.p2(42, "Foo")
      ]

      [fourth, third, second, first] =
        init_commit_history([
          [
            add: graph,
            message: "Initial commit",
            time: datetime(4)
          ],
          [
            # this leads to a different effective change
            add: [{EX.S3, EX.p3(), "foo"}],
            remove: EX.S1 |> EX.p1(EX.O1),
            committer: agent(:agent_jane),
            message: "Second commit",
            time: datetime(3)
          ],
          [
            # this leads to a different effective change
            add: [{EX.S4, EX.p4(), EX.O4}, {EX.S3, EX.p3(), "foo"}],
            message: "Third commit",
            time: datetime(2)
          ],
          [
            # this leads to a different effective change
            update: [{EX.S5, EX.p5(), EX.O5}, graph],
            message: "Fourth commit",
            time: datetime(1)
          ]
        ])

      assert Ontogen.changeset!() ==
               merged([first, second, third, fourth])
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
          message: "Third commit"
        ],
        [
          # this leads to a different effective change
          update: [{EX.S5, EX.p5(), EX.O5}, graph],
          message: "Fourth commit"
        ]
      ])
    end
  end

  describe "Ontogen.changeset/1 with :resource" do
    test "on a clean repo without commits" do
      assert Ontogen.changeset(resource: EX.S1) ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "target commit (default)" do
      [target_commit | _] = init_resource_history()

      changeset = Ontogen.changeset!(resource: EX.S1)

      assert changeset == Ontogen.changeset!(resource: EX.S1, target: target_commit)
      assert changeset == EffectiveChangeset.new!(replace: [{EX.S1, EX.p2(), EX.O2}])
    end

    test "with a specified base commit" do
      [fourth, third, second, first] = init_resource_history()

      assert Ontogen.changeset!(resource: EX.S1, base: first) ==
               resource_limited_merge([second, third, fourth], EX.S1)

      assert Ontogen.changeset(resource: EX.S1, base: fourth) ==
               {:ok, nil}
    end

    test "with a specified target commit" do
      [fourth, _third, _second, first] = history = init_resource_history()

      assert Ontogen.changeset!(resource: EX.S1, target: fourth.__id__) ==
               history |> Enum.reverse() |> resource_limited_merge(EX.S1)

      assert Ontogen.changeset!(resource: EX.S1, target: first.__id__) ==
               resource_limited_merge([first], EX.S1)
    end

    test "with a specified base and target commit" do
      [fourth, third, second, first] = init_resource_history()

      assert Ontogen.changeset(resource: EX.S1, base: second, target: third) ==
               EffectiveChangeset.new(third)

      assert Ontogen.changeset(resource: EX.S1, base: first, target: fourth) ==
               {:ok, resource_limited_merge([second, third, fourth], EX.S1)}
    end

    test "when the specified target commit comes later than the base commit" do
      [fourth, _third, _second, first] = init_resource_history()

      assert Ontogen.changeset(resource: EX.S1, base: fourth.__id__, target: first.__id__) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    defp resource_limited_merge(commits, subject) do
      commits
      |> Enum.map(
        &(&1
          |> EffectiveChangeset.new!()
          |> EffectiveChangeset.limit(:resource, subject))
      )
      |> merged()
    end

    defp init_resource_history do
      # TODO: add branch, when possible, to test it gets ignored
      [fourth, _, _, third, second, _, first] =
        init_commit_history([
          [
            add: [
              EX.S1 |> EX.p1(EX.O1),
              EX.S2 |> EX.p2(42, "Foo")
            ],
            message: "Initial commit"
          ],
          [
            add: {EX.S3, EX.p3(), "foo"},
            message: "Irrelevant commit"
          ],
          [
            # this leads to a different effective change
            add: [{EX.S3, EX.p3(), "foo"}, {EX.S3, EX.p3(), "bar"}],
            remove: EX.S1 |> EX.p1(EX.O1),
            committer: agent(:agent_jane),
            message: "Second relevant commit"
          ],
          [
            add: {EX.S1, EX.p4(), EX.O4},
            message: "Third relevant commit"
          ],
          [
            add: [{EX.S1, EX.p4(), EX.O4}, {EX.S4, EX.p4(), EX.O4}],
            message: "Irrelevant effective commit"
          ],
          [
            add: {EX.S5, EX.p2(), EX.O2},
            message: "Another irrelevant commit"
          ],
          [
            replace: [{EX.S1, EX.p2(), EX.O2}, {EX.S2, EX.p2(), EX.O2}],
            message: "Fourth relevant commit"
          ]
        ])

      [fourth, third, second, first]
    end
  end

  defp merged(commits) do
    commits
    |> Enum.map(&EffectiveChangeset.new!/1)
    |> EffectiveChangeset.merge()
  end
end
