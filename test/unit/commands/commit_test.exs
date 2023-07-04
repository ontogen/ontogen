defmodule Ontogen.Commands.CommitTest do
  use Ontogen.Local.Repo.Test.Case, async: false

  doctest Ontogen.Commands.Commit

  alias Ontogen.{Local, ProvGraph, Proposition, InvalidCommitError}

  test "initial commit with implicit utterance" do
    refute Repo.head()

    expected_insertion = Proposition.new!(graph())
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    utterance = utterance(time: datetime(-1, :day))

    assert {:ok, %Ontogen.Commit{} = commit} =
             Repo.commit(
               insert: graph(),
               data_source: dataset(),
               speaker: agent(),
               committer: committer,
               time: time,
               utterance_time: datetime(-1, :day),
               message: message
             )

    assert commit.parent == nil
    assert commit.utterance == utterance
    assert commit.insertion == expected_insertion
    assert commit.committer == committer
    assert commit.time == time
    assert commit.message == message

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
                    utterance,
                    expected_insertion,
                    committer
                  ]
                  |> Enum.map(&Grax.to_rdf!/1)
                ],
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "initial commit with explicit utterance" do
    refute Repo.head()

    utterance = utterance()

    expected_insertion = utterance.insertion
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    assert {:ok,
            %Ontogen.Commit{
              parent: nil,
              utterance: ^utterance,
              insertion: ^expected_insertion,
              committer: ^committer,
              time: ^time,
              message: ^message
            } = commit} =
             Repo.commit(
               utterance: utterance,
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
    assert Repo.commit(insert: graph(), utterance: graph()) ==
             {:error,
              InvalidCommitError.exception(
                reason: "utterances are not allowed with other changes"
              )}
  end

  describe "defaults" do
    test "with implicit utterance" do
      refute Repo.head()

      expected_insertion = Proposition.new!(graph())

      assert {:ok, commit} = Repo.commit(insert: graph())

      assert commit.insertion == expected_insertion
      assert commit.committer == Local.agent()
      assert DateTime.diff(DateTime.utc_now(), commit.time, :second) <= 1

      assert commit.utterance.insertion == expected_insertion
      assert commit.utterance.speaker == Local.agent()
      assert DateTime.diff(DateTime.utc_now(), commit.utterance.time, :second) <= 1

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

    test "with explicit utterance" do
      refute Repo.head()

      expected_insertion = utterance().insertion
      committer = agent(:agent_jane)
      time = datetime()
      message = "Initial commit"

      assert {:ok,
              %Ontogen.Commit{
                parent: nil,
                insertion: ^expected_insertion,
                committer: ^committer,
                time: ^time,
                message: ^message
              } = commit} =
               Repo.commit(
                 utterance: utterance_attrs(),
                 committer: committer,
                 time: time,
                 message: message
               )

      assert commit.utterance == utterance()

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

    assert {:ok, second_commit} =
             Repo.commit(
               insert: insert,
               delete: delete,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert second_commit.parent == first_commit.__id__
    assert second_commit.insertion == Proposition.new!(insert)
    assert second_commit.deletion == Proposition.new!(delete)

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
                  Proposition.new!(graph()),
                  Proposition.new!(insert),
                  Proposition.new!(delete),
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

    original_update = Proposition.new!(update)

    expected_update_proposition = Proposition.new!(expected_update)
    expected_delete_proposition = Proposition.new!(expected_delete)

    assert {:ok, new_commit} =
             Repo.commit(
               update: update,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.update == expected_update_proposition
    assert new_commit.overwrite == expected_delete_proposition
    assert new_commit.deletion == nil

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
                  Proposition.new!(graph()),
                  expected_update_proposition,
                  expected_delete_proposition,
                  original_update,
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

    insert_proposition = Proposition.new!(insert)
    replacement_proposition = Proposition.new!(replace)
    overwrite_proposition = Proposition.new!(expected_delete)

    utterance_args = [
      insert: insert,
      replace: replace,
      time: datetime(-1, :day)
    ]

    utterance = Ontogen.utterance!(utterance_args)

    assert {:ok, new_commit} =
             Repo.commit(
               utterance: utterance_args,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.utterance == utterance
    assert new_commit.insertion == insert_proposition
    assert new_commit.replacement == replacement_proposition
    assert new_commit.overwrite == overwrite_proposition

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
                  Proposition.new!(graph()),
                  insert_proposition,
                  replacement_proposition,
                  overwrite_proposition,
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

      expected_insert_proposition = Proposition.new!(expected_insert)
      expected_delete_proposition = Proposition.new!(expected_delete)

      utterance =
        utterance(
          insert: insert,
          delete: delete,
          speaker: agent(:agent_jane),
          time: datetime(),
          data_source: nil
        )

      assert {:ok, new_commit} =
               Repo.commit(
                 insert: insert,
                 delete: delete,
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.insertion == expected_insert_proposition
      assert new_commit.deletion == expected_delete_proposition
      assert new_commit.utterance == utterance

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
                    utterance,
                    Proposition.new!(graph()),
                    expected_insert_proposition,
                    expected_delete_proposition,
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

      expected_insertion_proposition = Proposition.new!(expected_insert)
      expected_deletion_proposition = Proposition.new!(expected_delete)

      assert {:ok, new_commit} =
               Repo.commit(
                 utterance: [
                   insert: insert,
                   delete: delete,
                   time: datetime()
                 ],
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.utterance ==
               Ontogen.utterance!(
                 insert: insert,
                 delete: delete,
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.insertion == expected_insertion_proposition
      assert new_commit.deletion == expected_deletion_proposition

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
                    Proposition.new!(graph()),
                    expected_insertion_proposition,
                    expected_deletion_proposition,
                    Ontogen.utterance!(
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

    test "when there are no remaining changes; with no_effective_changes: :error" do
      [last_commit] = init_commit_history()
      {:ok, last_dataset} = Repo.fetch_dataset()
      {:ok, last_prov_graph} = Repo.fetch_prov_graph()

      assert Repo.commit(
               insert: Proposition.graph(last_commit.insertion),
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime(),
               no_effective_changes: :error
             ) ==
               {:error, :no_effective_changes}

      # does not change the head in the dataset of the repo
      assert Repo.head() == last_commit

      # does not change the dataset
      assert Repo.fetch_dataset() == {:ok, last_dataset}

      # does not change the provenance graph
      assert Repo.fetch_prov_graph() == {:ok, last_prov_graph}
    end
  end
end
