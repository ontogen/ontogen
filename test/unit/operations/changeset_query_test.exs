defmodule Ontogen.Operations.ChangesetQueryTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.ChangesetQuery

  alias Ontogen.Commit.Changeset

  describe "Ontogen.dataset_changes/1" do
    test "on a clean repo without commits" do
      assert Ontogen.dataset_changes() == {:error, :no_head}
    end

    test "last commit (default)" do
      [last_commit | _] = init_history()

      assert Ontogen.dataset_changes() == Ontogen.dataset_changes(last: last_commit.__id__)
    end

    test "with a specified start commit" do
      [fourth, third, second, first] = init_history()

      assert Ontogen.dataset_changes(first: first) ==
               {:ok, Changeset.merge([second, third, fourth])}

      assert Ontogen.dataset_changes(first: second) ==
               {:ok, Changeset.merge([third, fourth])}

      assert Ontogen.dataset_changes(first: third) ==
               Changeset.new(fourth)

      assert Ontogen.dataset_changes(first: fourth) ==
               {:ok, nil}
    end

    test "with a specified end commit" do
      [fourth, third, second, first] = history = init_history()

      assert Ontogen.dataset_changes(last: fourth.__id__) ==
               {:ok, history |> Enum.reverse() |> Changeset.merge()}

      assert Ontogen.dataset_changes(last: third.__id__) ==
               {:ok, Changeset.merge([first, second, third])}

      assert Ontogen.dataset_changes(last: second.__id__) ==
               {:ok, Changeset.merge([first, second])}

      assert Ontogen.dataset_changes(last: first.__id__) ==
               Changeset.new(first)
    end

    test "with a specified start and end commit" do
      [fourth, third, second, first] = init_history()

      assert Ontogen.dataset_changes(first: first.__id__, last: fourth.__id__) ==
               {:ok, Changeset.merge([second, third, fourth])}

      assert Ontogen.dataset_changes(first: second.__id__, last: third.__id__) ==
               Changeset.new(third)
    end

    test "when the specified end commit comes later than the start commit" do
      [_fourth, third, second, _first] = init_history()

      assert Ontogen.dataset_changes(first: third.__id__, last: second.__id__) ==
               {:ok, nil}
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

  describe "Ontogen.resource_changes/1" do
    test "on a clean repo without commits" do
      assert Ontogen.resource_changes(EX.S1) == {:error, :no_head}
    end

    test "last commit (default)" do
      [last_commit | _] = init_resource_history()

      changeset = Ontogen.resource_changes(EX.S1)

      assert changeset == Ontogen.resource_changes(EX.S1, last: last_commit)
      assert changeset == Changeset.new(replace: [{EX.S1, EX.p2(), EX.O2}])
    end

    test "with a specified start commit" do
      [fourth, third, second, first] = init_resource_history()

      assert Ontogen.resource_changes(EX.S1, first: first) ==
               {:ok, resource_limited_merge([second, third, fourth], EX.S1)}

      assert Ontogen.resource_changes(EX.S1, first: third) ==
               {:ok, resource_limited_merge([fourth], EX.S1)}

      assert Ontogen.resource_changes(EX.S1, first: fourth) ==
               {:ok, nil}
    end

    test "with a specified end commit" do
      [fourth, third, second, first] = history = init_resource_history()

      assert Ontogen.resource_changes(EX.S1, last: fourth.__id__) ==
               {:ok, history |> Enum.reverse() |> resource_limited_merge(EX.S1)}

      assert Ontogen.resource_changes(EX.S1, last: third.__id__) ==
               {:ok, resource_limited_merge([first, second, third], EX.S1)}

      assert Ontogen.resource_changes(EX.S1, last: first.__id__) ==
               {:ok, resource_limited_merge([first], EX.S1)}
    end

    test "with a specified start and end commit" do
      [fourth, third, second, first] = init_resource_history()

      assert Ontogen.resource_changes(EX.S1, first: second, last: third) ==
               Changeset.new(third)

      assert Ontogen.resource_changes(EX.S1, first: first, last: fourth) ==
               {:ok, resource_limited_merge([second, third, fourth], EX.S1)}
    end

    test "when the specified end commit comes later than the start commit" do
      [fourth, _third, _second, first] = init_resource_history()

      assert Ontogen.resource_changes(EX.S1, first: fourth.__id__, last: first.__id__) ==
               {:ok, nil}
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
