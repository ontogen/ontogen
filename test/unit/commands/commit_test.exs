defmodule Ontogen.Commands.CommitTest do
  use Ontogen.Local.Repo.Test.Case, async: false

  doctest Ontogen.Commands.Commit

  alias Ontogen.{Local, ProvGraph, Expression, EffectiveExpression, InvalidCommitError}
  alias Ontogen.Commands.CreateUtterance

  test "initial commit without utterance" do
    refute Repo.head()

    expected_insertion = Expression.new!(graph())
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    assert {:ok,
            %Ontogen.Commit{
              parent: nil,
              insertion: ^expected_insertion,
              deletion: [],
              committer: ^committer,
              time: ^time,
              message: ^message
            } = commit,
            nil} =
             Repo.commit(
               insert: graph(),
               committer: committer,
               time: time,
               message: message
             )

    # updates the head in the dataset of the repo
    assert Repo.head() == commit

    # updates the repo graph
    assert Repo.repository() |> flatten_property([:dataset, :head]) == stored_repo()

    # inserts the statements
    assert Repo.fetch_dataset() == {:ok, graph()}

    # inserts the provenance
    assert Repo.fetch_prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  [
                    commit,
                    expected_insertion,
                    committer
                  ]
                  |> Enum.map(&Grax.to_rdf!/1)
                ],
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "initial commit with directly given utterance" do
    refute Repo.head()

    utterance = utterance()
    expected_insertion = utterance.insertion
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    assert {:ok,
            %Ontogen.Commit{
              parent: nil,
              insertion: ^expected_insertion,
              deletion: [],
              committer: ^committer,
              time: ^time,
              message: ^message
            } = commit,
            ^utterance} =
             Repo.commit(
               utter: utterance,
               committer: committer,
               time: time,
               message: message
             )

    # updates the head in the dataset of the repo
    assert Repo.head() == commit

    # updates the repo graph
    assert Repo.repository() |> flatten_property([:dataset, :head]) == stored_repo()

    # inserts the uttered statements
    assert Repo.fetch_dataset() == {:ok, graph()}

    # inserts the provenance
    assert Repo.fetch_prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  commit,
                  expected_insertion,
                  committer,
                  utterance()
                ]
                |> Enum.map(&Grax.to_rdf!/1),
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "when direct changes and an utterance given" do
    assert Repo.commit(insert: graph(), utter: graph()) ==
             {:error,
              InvalidCommitError.exception(
                reason: "utterances are not allowed with other changes"
              )}
  end

  describe "defaults" do
    test "without utterance" do
      refute Repo.head()

      expected_insertion = Expression.new!(graph())

      assert {:ok, commit, nil} = Repo.commit(insert: graph())

      assert commit.insertion == expected_insertion
      assert commit.committer == Local.agent()
      assert DateTime.diff(DateTime.utc_now(), commit.time, :second) <= 1

      # inserts the provenance
      assert Repo.fetch_prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    commit,
                    expected_insertion,
                    Local.agent()
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "with utterance" do
      refute Repo.head()

      expected_insertion = utterance().insertion
      committer = agent(:agent_jane)
      time = datetime()
      message = "Initial commit"

      assert {:ok,
              %Ontogen.Commit{
                parent: nil,
                insertion: ^expected_insertion,
                deletion: [],
                committer: ^committer,
                time: ^time,
                message: ^message
              } = commit,
              utterance} =
               Repo.commit(
                 utter: utterance_attrs(),
                 committer: committer,
                 time: time,
                 message: message
               )

      assert utterance == utterance()

      # inserts the provenance
      assert Repo.fetch_prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    commit,
                    expected_insertion,
                    committer,
                    utterance()
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end
  end

  test "subsequent commit" do
    [first_commit] = init_commit_history()

    insert = RDF.graph({EX.S3, EX.p3(), "foo"})
    delete = RDF.graph(EX.S1 |> EX.p1(EX.O1))

    assert {:ok, second_commit, nil} =
             Repo.commit(
               insert: insert,
               delete: delete,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert second_commit.parent == first_commit.__id__
    assert second_commit.insertion == Expression.new!(insert)
    assert second_commit.deletion == [Expression.new!(delete)]

    # updates the head in the dataset of the repo
    assert Repo.head() == second_commit

    # updates the repo graph
    assert Repo.repository() |> flatten_property([:dataset, :head]) == stored_repo()

    # applies the changes
    assert Repo.fetch_dataset() ==
             {:ok, graph() |> Graph.add(insert) |> Graph.delete(delete)}

    # inserts the provenance
    assert Repo.fetch_prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  first_commit,
                  second_commit,
                  Expression.new!(graph()),
                  Expression.new!(insert),
                  Expression.new!(delete),
                  Local.agent(),
                  agent(:agent_jane)
                ]
                |> Enum.map(&Grax.to_rdf!/1),
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "update" do
    [last_commit] = init_commit_history()

    update = [
      {EX.S3, EX.p3(), "foo"},
      EX.S2 |> EX.p2("Foo", "Bar")
    ]

    expected_update = RDF.graph([EX.S3 |> EX.p3("foo"), EX.S2 |> EX.p2("Bar")])
    expected_delete = RDF.graph(EX.S2 |> EX.p2(42))

    original_update = Expression.new!(update)

    assert {:ok, new_commit, nil} =
             Repo.commit(
               update: update,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.update == EffectiveExpression.new!(original_update, expected_update)

    assert new_commit.deletion == [
             EffectiveExpression.new!(original_update, expected_delete, only_subset: false)
           ]

    # updates the head in the dataset of the repo
    assert Repo.head() == new_commit

    # applies the changes
    assert Repo.fetch_dataset() ==
             {:ok,
              graph()
              |> Graph.add(expected_update)
              |> Graph.delete(expected_delete)}

    # inserts the provenance
    assert Repo.fetch_prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  last_commit,
                  new_commit,
                  Expression.new!(graph()),
                  EffectiveExpression.new!(original_update, expected_update),
                  EffectiveExpression.new!(original_update, expected_delete, only_subset: false),
                  Local.agent(),
                  agent(:agent_jane)
                ]
                |> Enum.map(&Grax.to_rdf!/1),
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "replacement (with utterance)" do
    [last_commit] = init_commit_history()

    insert = {EX.S4, EX.p4(), EX.O4}

    replace = [
      {EX.S3, EX.p3(), "foo"},
      EX.S2 |> EX.p3("Bar")
    ]

    expected_delete = RDF.graph(EX.S2 |> EX.p2(42, "Foo"))

    insert_expr = Expression.new!(insert)
    replacement_expr = Expression.new!(replace)

    utterance_args = [
      insert: insert,
      replace: replace,
      time: datetime(-1, :day)
    ]

    utterance = CreateUtterance.call!(utterance_args)

    assert {:ok, new_commit, ^utterance} =
             Repo.commit(
               utter: utterance_args,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.insertion == insert_expr
    assert new_commit.replacement == replacement_expr

    # updates the head in the dataset of the repo
    assert Repo.head() == new_commit

    # applies the changes
    assert Repo.fetch_dataset() ==
             {:ok,
              graph()
              |> Graph.add(insert)
              |> Graph.add(replace)
              |> Graph.delete(expected_delete)}

    # inserts the provenance
    assert Repo.fetch_prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  last_commit,
                  new_commit,
                  Expression.new!(graph()),
                  insert_expr,
                  replacement_expr,
                  EffectiveExpression.new!(replacement_expr, expected_delete, only_subset: false),
                  utterance,
                  Local.agent(),
                  agent(:agent_jane)
                ]
                |> Enum.map(&Grax.to_rdf!/1),
                prefixes: ProvGraph.prefixes()
              )}
  end

  describe "handling of changes that already apply" do
    test "only the real changes are committed" do
      [last_commit] = init_commit_history()

      insert = [
        {EX.S3, EX.p3(), "foo"},
        # This statement was already inserted with the first commit
        EX.S1 |> EX.p1(EX.O1)
      ]

      delete = [
        EX.S2 |> EX.p2(42),
        # This statement is not present
        EX.S3 |> EX.p3(EX.O3)
      ]

      expected_insert = RDF.graph(EX.S3 |> EX.p3("foo"))
      expected_delete = RDF.graph(EX.S2 |> EX.p2(42))

      original_insertion = Expression.new!(insert)
      original_deletion = Expression.new!(delete)

      assert {:ok, new_commit, nil} =
               Repo.commit(
                 insert: insert,
                 delete: delete,
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.insertion == EffectiveExpression.new!(original_insertion, expected_insert)

      assert new_commit.deletion == [
               EffectiveExpression.new!(original_deletion, expected_delete)
             ]

      # updates the head in the dataset of the repo
      assert Repo.head() == new_commit

      # applies the changes
      assert Repo.fetch_dataset() ==
               {:ok,
                graph()
                |> Graph.add(expected_insert)
                |> Graph.delete(expected_delete)}

      # inserts the provenance
      assert Repo.fetch_prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    last_commit,
                    new_commit,
                    Expression.new!(graph()),
                    EffectiveExpression.new!(original_insertion, expected_insert),
                    EffectiveExpression.new!(original_deletion, expected_delete),
                    Local.agent(),
                    agent(:agent_jane)
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "with utterance" do
      [last_commit] = init_commit_history()

      insert = [
        {EX.S3, EX.p3(), "foo"},
        # This statement was already inserted with the first commit
        EX.S2 |> EX.p2("Foo")
      ]

      delete = [
        EX.S1 |> EX.p1(EX.O1),
        # This statement is not present
        EX.S3 |> EX.p3(EX.O3)
      ]

      expected_insert = RDF.graph(EX.S3 |> EX.p3("foo"))
      expected_delete = RDF.graph(EX.S1 |> EX.p1(EX.O1))

      original_insertion = Expression.new!(insert)
      original_deletion = Expression.new!(delete)

      assert {:ok, new_commit, utterance} =
               Repo.commit(
                 utter: [
                   insert: insert,
                   delete: delete,
                   time: datetime()
                 ],
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert utterance ==
               Ontogen.utterance!(
                 insert: insert,
                 delete: delete,
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__

      # updates the head in the dataset of the repo
      assert Repo.head() == new_commit

      # applies the changes
      assert Repo.fetch_dataset() ==
               {:ok,
                graph()
                |> Graph.add(expected_insert)
                |> Graph.delete(expected_delete)}

      # inserts the provenance
      assert Repo.fetch_prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    last_commit,
                    new_commit,
                    Expression.new!(graph()),
                    EffectiveExpression.new!(original_insertion, expected_insert),
                    EffectiveExpression.new!(original_deletion, expected_delete),
                    CreateUtterance.call!(
                      insert: insert,
                      delete: delete,
                      time: datetime()
                    ),
                    Local.agent(),
                    agent(:agent_jane)
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "when there are no remaining changes; without an utterance" do
      [last_commit] = init_commit_history()
      {:ok, last_dataset} = Repo.fetch_dataset()
      {:ok, last_prov_graph} = Repo.fetch_prov_graph()

      assert Repo.commit(
               insert: Expression.graph(last_commit.insertion),
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             ) ==
               {:error, :no_effective_changes}

      # does not change the head in the dataset of the repo
      assert Repo.head() == last_commit

      # does not change the dataset
      assert Repo.fetch_dataset() == {:ok, last_dataset}

      # does not change the provenance graph
      assert Repo.fetch_prov_graph() == {:ok, last_prov_graph}
    end

    test "when there are no remaining changes; with a new utterance" do
      [last_commit] = init_commit_history()
      {:ok, last_dataset} = Repo.fetch_dataset()
      {:ok, last_prov_graph} = Repo.fetch_prov_graph()

      assert {:ok, :no_effective_changes, utterance} =
               Repo.commit(
                 utter: [
                   insert: Expression.graph(last_commit.insertion),
                   time: datetime()
                 ],
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert utterance ==
               Ontogen.utterance!(
                 insert: Expression.graph(last_commit.insertion),
                 time: datetime()
               )

      # does not change the head in the dataset of the repo
      assert Repo.head() == last_commit

      # does not change the dataset
      assert Repo.fetch_dataset() == {:ok, last_dataset}

      # adds only the utterance on the provenance graph
      assert Repo.fetch_prov_graph() ==
               {:ok, last_prov_graph |> Graph.add(Grax.to_rdf!(utterance))}
    end
  end
end
