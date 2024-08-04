defmodule Ontogen.Operations.HistoryQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.HistoryQuery

  alias Ontogen.{InvalidCommitRangeError, EmptyRepositoryError}

  describe "history/1" do
    test "on empty repo" do
      assert {:ok, %Graph{}} = Ontogen.history()
    end

    test "with defaults, it returns the full history graph" do
      history = init_history()

      assert Ontogen.history() ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
    end

    test "with :resource" do
      history = init_resource_history()

      assert Ontogen.history(resource: EX.S1) ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
    end

    test "with :statement" do
      history = init_statement_history()

      assert Ontogen.history(statement: statement_of_interest()) ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
    end

    test "with :statement and subject-predicate-pair on :statement" do
      history = init_predication_history()

      assert Ontogen.history(statement: predication_of_interest()) ==
               {:ok,
                RDF.graph(Enum.map(history, &Grax.to_rdf!(&1)))
                |> Graph.add_prefixes(RDF.standard_prefixes())
                |> Graph.add_prefixes(og: Og, rtc: RTC)}
    end
  end

  describe "log/1" do
    test "on a clean repo without commits" do
      assert Ontogen.log() ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "full log" do
      history = init_history()

      assert Ontogen.log() == {:ok, history}
    end

    test "with a specified base commit" do
      [_fourth, _third, _second, first] = history = init_history()

      assert Ontogen.log(base: first) == {:ok, Enum.slice(history, 0..2)}
    end

    test "with a specified target commit" do
      [fourth, _third, _second, first] = history = init_history()

      assert Ontogen.log(target: fourth.__id__) == {:ok, history}
      assert Ontogen.log(target: first) == {:ok, Enum.slice(history, 3..3)}
    end

    test "with a specified base and target commit" do
      [_fourth, third, second, _first] = history = init_history()

      assert Ontogen.log(base: second, target: third) == {:ok, Enum.slice(history, 1..1)}
      assert Ontogen.log(range: {second, third}) == {:ok, Enum.slice(history, 1..1)}
    end

    test "with relative base commit" do
      [_fourth, third, second, _first] = history = init_history()

      assert Ontogen.log(base: 1) == {:ok, Enum.slice(history, 0..0)}
      assert Ontogen.log(base: 4) == {:ok, history}
      assert Ontogen.log(target: third, base: 1) == {:ok, Enum.slice(history, 1..1)}
      assert Ontogen.log(target: second, base: 2) == {:ok, Enum.slice(history, 2..3)}
    end

    test "empty range" do
      [fourth, _third, _second, _first] = init_history()

      assert Ontogen.log(base: fourth) == {:ok, []}
    end

    test "commits are ordered according to parent chain" do
      history =
        init_commit_history([
          [
            add: statement(1),
            message: "First commit",
            time: datetime(2)
          ],
          [
            add: statement(2),
            message: "Second commit",
            time: datetime(1)
          ]
        ])

      assert Ontogen.log() == {:ok, history}
    end

    test "when the specified target commit comes later than the base commit" do
      [fourth, _third, _second, first] = init_history()

      assert Ontogen.log(base: fourth, target: first) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "out of range errors" do
      history = init_history()
      independent_commit = commit()

      assert independent_commit not in history

      assert Ontogen.log(target: independent_commit) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Ontogen.log(base: independent_commit) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Ontogen.log(base: 99) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "formatted history" do
      [fourth, third, second, first] = init_history()

      assert Ontogen.log(format: :oneline, color: false) ==
               {:ok,
                """
                #{hash_from_iri(fourth.__id__)} #{first_line(fourth.message)}
                #{hash_from_iri(third.__id__)} #{first_line(third.message)}
                #{hash_from_iri(second.__id__)} #{first_line(second.message)}
                #{hash_from_iri(first.__id__)} #{first_line(first.message)}
                """
                |> String.trim_trailing()}
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
    end
  end

  describe "log/1 with :resource" do
    test "on a clean repo without commits" do
      assert Ontogen.log(resource: EX.S1) ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "full log" do
      history = init_resource_history()

      assert Ontogen.log(resource: EX.S1) == {:ok, history}
    end

    test "with a specified base commit" do
      [_fourth, _third, second, _first] = history = init_resource_history()

      assert Ontogen.log(resource: EX.S1, base: second.__id__) ==
               {:ok, Enum.slice(history, 0..1)}
    end

    test "with a specified target commit" do
      [fourth, _third, second, _first] = history = init_resource_history()

      assert Ontogen.log(resource: EX.S1, target: fourth.__id__) == {:ok, history}

      assert Ontogen.log(resource: EX.S1, target: second.__id__) ==
               {:ok, Enum.slice(history, 2..3)}
    end

    test "with relative base commit" do
      [_fourth, _third, second, _first] = history = init_resource_history()

      assert Ontogen.log(resource: EX.S1, base: 1) ==
               {:ok, Enum.slice(history, 0..0)}

      # the other commits are out of range because irrelevant commits are in between
      assert Ontogen.log(resource: EX.S1, base: 4) ==
               {:ok, Enum.slice(history, 0..1)}

      assert Ontogen.log(resource: EX.S1, target: second, base: 2) ==
               {:ok, Enum.slice(history, 2..2)}
    end

    test "with a specified base and target commit" do
      [fourth, _third, _second, first] = history = init_resource_history()

      assert Ontogen.log(resource: EX.S1, base: first.__id__, target: fourth.__id__) ==
               {:ok, Enum.slice(history, 0..2)}
    end

    test "when the specified target commit comes later than the base commit" do
      [_fourth, third, second, _first] = init_resource_history()

      assert Ontogen.log(resource: EX.S1, base: third.__id__, target: second.__id__) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
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

  describe "log/1 with :statement" do
    test "on a clean repo without commits" do
      assert Ontogen.log(statement: statement_of_interest()) ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "full log" do
      history = init_statement_history()

      assert Ontogen.log(statement: statement_of_interest()) == {:ok, history}
    end

    test "with a specified base commit" do
      [_third, _second, first] = history = init_statement_history()

      assert Ontogen.log(statement: statement_of_interest(), base: first.__id__) ==
               {:ok, Enum.slice(history, 0..1)}
    end

    test "with a specified target commit" do
      [third, _second, first] = history = init_statement_history()

      assert Ontogen.log(statement: statement_of_interest(), target: third.__id__) ==
               {:ok, history}

      assert Ontogen.log(statement: statement_of_interest(), target: first.__id__) ==
               {:ok, Enum.slice(history, 2..2)}
    end

    test "with a specified base and target commit" do
      [_third, second, first] = history = init_statement_history()

      assert Ontogen.log(
               statement: statement_of_interest(),
               base: first.__id__,
               target: second.__id__
             ) ==
               {:ok, Enum.slice(history, 1..1)}
    end

    test "when the specified target commit comes later than the base commit" do
      [_third, second, first] = init_statement_history()

      assert Ontogen.log(
               statement: statement_of_interest(),
               base: second.__id__,
               target: first.__id__
             ) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    defp statement_of_interest, do: {EX.S1, EX.p1(), EX.O1}

    defp init_statement_history do
      [third, _, _, second, _, first] =
        init_commit_history([
          [
            add: [
              EX.S1 |> EX.p1(EX.O1),
              EX.S2 |> EX.p2(42, "Foo")
            ],
            message: "Initial commit"
          ],
          [
            add: {EX.S3, EX.p3(), EX.O3},
            message: "Irrelevant commit"
          ],
          [
            add: {EX.S3, EX.p3(), "foo"},
            remove: EX.S1 |> EX.p1(EX.O1),
            committer: agent(:agent_jane),
            message: "Second relevant commit"
          ],
          [
            add: {EX.S1, EX.p1(), EX.O2},
            message: "Another irrelevant commit"
          ],
          [
            add: {EX.S4, EX.p4(), EX.O4},
            message: "Another irrelevant commit"
          ],
          [
            # this leads to a different effective change
            update: [EX.S1 |> EX.p1(EX.O1), {EX.S4, EX.p4(), EX.O4}],
            message: "Third commit"
          ]
        ])

      [third, second, first]
    end
  end

  describe "log/1 with subject-predicate-pair on :statement" do
    test "on a clean repo without commits" do
      assert Ontogen.log(statement: predication_of_interest()) ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "full log" do
      history = init_predication_history()

      assert Ontogen.log(statement: predication_of_interest()) == {:ok, history}
    end

    test "with a specified base commit" do
      [_fourth, _third, second, _first] = history = init_predication_history()

      assert Ontogen.log(statement: predication_of_interest(), base: second.__id__) ==
               {:ok, Enum.slice(history, 0..1)}
    end

    test "with a specified target commit" do
      [fourth, _third, _second, first] = history = init_predication_history()

      assert Ontogen.log(statement: predication_of_interest(), target: fourth.__id__) ==
               {:ok, history}

      assert Ontogen.log(statement: predication_of_interest(), target: first.__id__) ==
               {:ok, Enum.slice(history, 3..3)}
    end

    test "with a specified base and target commit" do
      [fourth, _third, _second, first] = history = init_predication_history()

      assert Ontogen.log(
               statement: predication_of_interest(),
               base: first.__id__,
               target: fourth.__id__
             ) ==
               {:ok, Enum.slice(history, 0..2)}
    end

    test "when the specified target commit comes later than the base commit" do
      [_fourth, third, second, _first] = init_predication_history()

      assert Ontogen.log(
               statement: predication_of_interest(),
               base: third.__id__,
               target: second.__id__
             ) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    defp predication_of_interest, do: {EX.S1, EX.p1()}

    defp init_predication_history do
      [fourth, _, third, second, _, first] =
        init_commit_history([
          [
            add: [
              EX.S1 |> EX.p1(EX.O1),
              EX.S2 |> EX.p2(42, "Foo")
            ],
            message: "Initial commit"
          ],
          [
            add: {EX.S3, EX.p3(), EX.O3},
            message: "Irrelevant commit"
          ],
          [
            # this leads to a different effective change
            add: [{EX.S3, EX.p3(), "foo"}, {EX.S3, EX.p3(), EX.O3}],
            remove: EX.S1 |> EX.p1(EX.O1),
            committer: agent(:agent_jane),
            message: "Second relevant commit"
          ],
          [
            # this leads to a different effective change (which caused the EffectiveProposition-origin-overlap-problem in the old effective change model)
            add: [{EX.S1, EX.p1(), EX.O2}, {EX.S3, EX.p3(), EX.O3}],
            message: "Third relevant commit"
          ],
          [
            add: {EX.S4, EX.p4(), EX.O4},
            message: "Another irrelevant commit"
          ],
          [
            update: EX.S1 |> EX.p1(EX.O1),
            message: "Fourth commit"
          ]
        ])

      [fourth, third, second, first]
    end
  end
end
