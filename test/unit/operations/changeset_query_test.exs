defmodule Ontogen.Operations.ChangesetQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.ChangesetQuery

  alias Ontogen.Commit.Changeset
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
               Changeset.merge([third, fourth])

      assert Ontogen.changeset!(base: fourth) == nil
    end

    test "with a specified target commit" do
      [fourth, _third, second, first] = history = init_history()

      assert Ontogen.changeset!(target: fourth.__id__) ==
               history |> Enum.reverse() |> Changeset.merge()

      assert Ontogen.changeset!(target: second.__id__) ==
               Changeset.merge([first, second])
    end

    test "with a specified base and target commit" do
      [fourth, third, second, first] = init_history()

      assert Ontogen.changeset!(base: first.__id__, target: fourth.__id__) ==
               Changeset.merge([second, third, fourth])

      assert Ontogen.changeset!(base: second.__id__, target: third.__id__) ==
               Changeset.new!(third)
    end

    test "with relative base commit" do
      [fourth, third, second, first] = history = init_history()

      assert Ontogen.changeset(base: 1) ==
               Changeset.new(fourth)

      assert Ontogen.changeset!(base: 4) ==
               Changeset.merge(Enum.reverse(history))

      assert Ontogen.changeset(target: third, base: 1) ==
               Changeset.new(third)

      assert Ontogen.changeset!(target: second, base: 2) ==
               Changeset.merge([second, first])
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
               Changeset.merge([first, second, third, fourth])
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
      assert changeset == Changeset.new!(replace: [{EX.S1, EX.p2(), EX.O2}])
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
               Changeset.new(third)

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
          |> Changeset.new!()
          |> Changeset.limit(:resource, subject))
      )
      |> Changeset.merge()
    end

    defp init_resource_history do
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
end
