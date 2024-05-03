defmodule Ontogen.Operations.RevisionQueryTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.RevisionQuery

  test "on a clean repo without commits" do
    assert Ontogen.revision(EX.S1) ==
             {:ok, RDF.graph()}
  end

  test "a single resource" do
    init_history()

    assert Ontogen.revision!(EX.S1) ==
             RDF.graph([
               EX.S1
               |> EX.p2(EX.O2)
             ])
  end

  test "non-existing resource" do
    init_history()

    assert Ontogen.revision!(EX.NonExisting) == RDF.graph()
  end

  test "multiple resources" do
    init_history()

    assert Ontogen.revision!([EX.S1, EX.S2, EX.S3, EX.NonExisting]) ==
             RDF.graph([
               EX.S1
               |> EX.p2(EX.O2),
               EX.S2
               |> EX.p2(EX.O2),
               EX.S3
               |> EX.p3(["foo", "bar"])
             ])
  end

  defp init_history do
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
