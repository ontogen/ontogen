defmodule Ontogen.Operations.CommitCommandTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.CommitCommand

  alias Ontogen.{Config, ProvGraph, SpeechAct, Proposition, InvalidCommitError}

  test "initial commit with implicit speech_act" do
    refute Ontogen.head()

    expected_insert = Proposition.new!(graph())
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    speech_act = speech_act(time: datetime(-1, :day))

    assert {:ok, %Ontogen.Commit{} = commit} =
             Ontogen.commit(
               insert: graph(),
               data_source: dataset(),
               speaker: agent(),
               committer: committer,
               time: time,
               speech_act_time: datetime(-1, :day),
               message: message
             )

    assert commit.parent == nil
    assert commit.speech_act == speech_act
    assert commit.insert == expected_insert
    assert commit.committer == committer
    assert commit.time == time
    assert commit.message == message

    # updates the head in the repo
    assert Ontogen.head() == commit

    # updates the repo graph in the store
    assert Ontogen.repository() |> flatten_property(:head) == stored_repo()

    # inserts the statements
    assert Ontogen.dataset() == {:ok, graph()}

    # inserts the provenance
    assert Ontogen.prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  [
                    commit,
                    speech_act,
                    expected_insert,
                    committer
                  ]
                  |> Enum.map(&Grax.to_rdf!/1)
                ],
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "initial commit with explicit speech_act" do
    refute Ontogen.head()

    speech_act = speech_act()

    expected_insert = speech_act.insert
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    assert {:ok,
            %Ontogen.Commit{
              parent: nil,
              speech_act: ^speech_act,
              insert: ^expected_insert,
              committer: ^committer,
              time: ^time,
              message: ^message
            } = commit} =
             Ontogen.commit(
               speech_act: speech_act,
               committer: committer,
               time: time,
               message: message
             )

    # updates the head in the dataset of the repo
    assert Ontogen.head() == commit

    # updates the repo graph in the store
    assert Ontogen.repository() |> flatten_property(:head) == stored_repo()

    # inserts the uttered statements
    assert Ontogen.dataset() == {:ok, graph()}

    # inserts the provenance
    assert Ontogen.prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  commit,
                  expected_insert,
                  committer,
                  speech_act()
                ]
                |> Enum.map(&Grax.to_rdf!/1),
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "when direct changes and a speech_act given" do
    assert Ontogen.commit(insert: graph(), speech_act: graph()) ==
             {:error,
              InvalidCommitError.exception(
                reason: "speech acts are not allowed with other changes"
              )}
  end

  describe "defaults" do
    # TODO: This is a flaky test on Oxigraph due to this issue: https://github.com/oxigraph/oxigraph/issues/524
    test "with implicit speech_act" do
      refute Ontogen.head()

      expected_insert = Proposition.new!(graph())

      assert {:ok, commit} = Ontogen.commit(insert: graph())

      assert commit.insert == expected_insert
      assert commit.committer == Config.agent()
      assert DateTime.diff(DateTime.utc_now(), commit.time, :second) <= 1

      assert commit.speech_act.insert == expected_insert
      assert commit.speech_act.speaker == Config.agent()
      assert DateTime.diff(DateTime.utc_now(), commit.speech_act.time, :second) <= 1

      # inserts the provenance
      assert Ontogen.prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    commit,
                    expected_insert,
                    Config.agent()
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "with explicit speech_act" do
      refute Ontogen.head()

      expected_insert = speech_act().insert
      committer = agent(:agent_jane)
      time = datetime()
      message = "Initial commit"

      assert {:ok,
              %Ontogen.Commit{
                parent: nil,
                insert: ^expected_insert,
                committer: ^committer,
                time: ^time,
                message: ^message
              } = commit} =
               Ontogen.commit(
                 speech_act: speech_act_attrs(),
                 committer: committer,
                 time: time,
                 message: message
               )

      assert commit.speech_act == speech_act()

      # inserts the provenance
      assert Ontogen.prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    commit,
                    expected_insert,
                    committer,
                    speech_act()
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
             Ontogen.commit(
               insert: insert,
               delete: delete,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert second_commit.parent == first_commit.__id__
    assert second_commit.insert == Proposition.new!(insert)
    assert second_commit.delete == Proposition.new!(delete)

    # updates the head in the dataset of the repo
    assert Ontogen.head() == second_commit

    # updates the repo graph in the store
    assert Ontogen.repository() |> flatten_property(:head) == stored_repo()

    # applies the changes
    assert Ontogen.dataset() ==
             {:ok, graph() |> Graph.add(insert) |> Graph.delete(delete)}

    # inserts the provenance
    assert Ontogen.prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  first_commit,
                  second_commit,
                  Proposition.new!(graph()),
                  Proposition.new!(insert),
                  Proposition.new!(delete),
                  Config.agent(),
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
             Ontogen.commit(
               update: update,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.update == expected_update_proposition
    assert new_commit.overwrite == expected_delete_proposition
    assert new_commit.delete == nil

    # updates the head in the dataset of the repo
    assert Ontogen.head() == new_commit

    # applies the changes
    assert Ontogen.dataset() ==
             {:ok,
              graph()
              |> Graph.add(expected_update)
              |> Graph.delete(expected_delete)}

    # inserts the provenance
    assert Ontogen.prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  last_commit,
                  new_commit,
                  Proposition.new!(graph()),
                  expected_update_proposition,
                  expected_delete_proposition,
                  original_update,
                  Config.agent(),
                  agent(:agent_jane)
                ]
                |> Enum.map(&Grax.to_rdf!/1),
                prefixes: ProvGraph.prefixes()
              )}
  end

  test "replace (with speech_act)" do
    [last_commit] = init_commit_history()

    insert = {EX.S4, EX.p4(), EX.O4}

    replace = [
      {EX.S3, EX.p3(), "foo"},
      EX.S2 |> EX.p3("Bar")
    ]

    expected_delete = RDF.graph(EX.S2 |> EX.p2(42, "Foo"))

    insert_proposition = Proposition.new!(insert)
    replace_proposition = Proposition.new!(replace)
    overwrite_proposition = Proposition.new!(expected_delete)

    speech_act_args = [
      insert: insert,
      replace: replace,
      time: datetime(-1, :day)
    ]

    speech_act = SpeechAct.new!(speech_act_args)

    assert {:ok, new_commit} =
             Ontogen.commit(
               speech_act: speech_act_args,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.speech_act == speech_act
    assert new_commit.insert == insert_proposition
    assert new_commit.replace == replace_proposition
    assert new_commit.overwrite == overwrite_proposition

    # updates the head in the dataset of the repo
    assert Ontogen.head() == new_commit

    # applies the changes
    assert Ontogen.dataset() ==
             {:ok,
              graph()
              |> Graph.add(insert)
              |> Graph.add(replace)
              |> Graph.delete(expected_delete)}

    # inserts the provenance
    assert Ontogen.prov_graph() ==
             {:ok,
              RDF.graph(
                [
                  last_commit,
                  new_commit,
                  Proposition.new!(graph()),
                  insert_proposition,
                  replace_proposition,
                  overwrite_proposition,
                  speech_act,
                  Config.agent(),
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

      speech_act =
        speech_act(
          insert: insert,
          delete: delete,
          speaker: agent(:agent_jane),
          time: datetime(),
          data_source: nil
        )

      assert {:ok, new_commit} =
               Ontogen.commit(
                 insert: insert,
                 delete: delete,
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.insert == expected_insert_proposition
      assert new_commit.delete == expected_delete_proposition
      assert new_commit.speech_act == speech_act

      # updates the head in the dataset of the repo
      assert Ontogen.head() == new_commit

      # applies the changes
      assert Ontogen.dataset() ==
               {:ok,
                graph()
                |> Graph.add(expected_insert)
                |> Graph.delete(expected_delete)}

      # inserts the provenance
      assert Ontogen.prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    last_commit,
                    new_commit,
                    speech_act,
                    Proposition.new!(graph()),
                    expected_insert_proposition,
                    expected_delete_proposition,
                    Config.agent(),
                    agent(:agent_jane)
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "with speech_act" do
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

      expected_insert_proposition = Proposition.new!(expected_insert)
      expected_delete_proposition = Proposition.new!(expected_delete)

      assert {:ok, new_commit} =
               Ontogen.commit(
                 speech_act: [
                   insert: insert,
                   delete: delete,
                   time: datetime()
                 ],
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.speech_act ==
               SpeechAct.new!(
                 insert: insert,
                 delete: delete,
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.insert == expected_insert_proposition
      assert new_commit.delete == expected_delete_proposition

      # updates the head in the dataset of the repo
      assert Ontogen.head() == new_commit

      # applies the changes
      assert Ontogen.dataset() ==
               {:ok,
                graph()
                |> Graph.add(expected_insert)
                |> Graph.delete(expected_delete)}

      # inserts the provenance
      assert Ontogen.prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    last_commit,
                    new_commit,
                    Proposition.new!(graph()),
                    expected_insert_proposition,
                    expected_delete_proposition,
                    SpeechAct.new!(
                      insert: insert,
                      delete: delete,
                      time: datetime()
                    ),
                    Config.agent(),
                    agent(:agent_jane)
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "when there are no remaining changes; with on_no_effective_changes: :error" do
      [last_commit] = init_commit_history()
      {:ok, last_dataset} = Ontogen.dataset()
      {:ok, last_prov_graph} = Ontogen.prov_graph()

      assert Ontogen.commit(
               insert: Proposition.graph(last_commit.insert),
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime(),
               on_no_effective_changes: :error
             ) ==
               {:error, :no_effective_changes}

      # does not change the head in the dataset of the repo
      assert Ontogen.head() == last_commit

      # does not change the dataset
      assert Ontogen.dataset() == {:ok, last_dataset}

      # does not change the provenance graph
      assert Ontogen.prov_graph() == {:ok, last_prov_graph}
    end
  end
end
