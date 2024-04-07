defmodule Ontogen.Operations.CommitCommandTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.CommitCommand

  alias Ontogen.{
    Config,
    ProvGraph,
    SpeechAct,
    Proposition,
    InvalidCommitError,
    NoEffectiveChanges
  }

  test "initial commit with implicit speech_act" do
    refute Ontogen.head()

    expected_add = Proposition.new!(graph())
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    speech_act = speech_act(time: datetime(-1, :day))

    assert {:ok, %Ontogen.Commit{} = commit} =
             Ontogen.commit(
               add: graph(),
               data_source: dataset(),
               speaker: agent(),
               committer: committer,
               time: time,
               speech_act_time: datetime(-1, :day),
               message: message
             )

    assert commit.parent == nil
    assert commit.speech_act == speech_act
    assert commit.add == expected_add
    assert commit.committer == committer
    assert commit.time == time
    assert commit.message == message

    assert_repo_state(
      commit,
      graph(),
      [
        commit,
        speech_act,
        expected_add,
        committer
      ]
      |> Enum.map(&Grax.to_rdf!/1)
    )
  end

  test "initial commit with explicit speech_act" do
    refute Ontogen.head()

    speech_act = speech_act()

    expected_add = speech_act.add
    committer = agent(:agent_jane)
    time = datetime()
    message = "Initial commit"

    assert {:ok,
            %Ontogen.Commit{
              parent: nil,
              speech_act: ^speech_act,
              add: ^expected_add,
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

    assert_repo_state(
      commit,
      graph(),
      [
        commit,
        speech_act,
        expected_add,
        committer
      ]
      |> Enum.map(&Grax.to_rdf!/1)
    )
  end

  test "when direct changes and a speech_act given" do
    assert Ontogen.commit(add: graph(), speech_act: graph()) ==
             {:error,
              InvalidCommitError.exception(
                reason: "speech acts are not allowed with other changes"
              )}
  end

  test "additional prov metadata" do
    refute Ontogen.head()

    expected_add = Proposition.new!(graph())
    message = "Initial commit"

    data_source = dataset() |> Grax.add_additional_statements({EX.p2(), EX.O2})
    speaker = agent() |> Grax.add_additional_statements({EX.p3(), EX.O3})

    speech_act =
      speech_act(
        add: graph(),
        data_source: data_source,
        speaker: speaker,
        time: datetime(-1)
      )
      |> Grax.add_additional_statements({EX.p1(), EX.O1})

    committer = agent(:agent_jane) |> Grax.add_additional_statements({EX.p4(), EX.O4})

    assert {:ok, %Ontogen.Commit{} = commit} =
             Ontogen.commit(
               speech_act: speech_act,
               committer: committer,
               time: datetime(),
               message: message,
               additional_prov_metadata: graph([1])
             )

    assert commit.parent == nil
    assert commit.speech_act == speech_act
    assert commit.committer == committer
    assert commit.add == expected_add

    assert_repo_state(
      commit,
      graph(),
      [
        graph([1])
        | [
            commit,
            speech_act,
            expected_add,
            data_source,
            speaker,
            committer
          ]
          |> Enum.map(&Grax.to_rdf!/1)
      ]
    )
  end

  describe "defaults" do
    # TODO: This is a flaky test on Oxigraph due to this issue: https://github.com/oxigraph/oxigraph/issues/524
    test "with implicit speech_act" do
      refute Ontogen.head()

      expected_add = Proposition.new!(graph())

      assert {:ok, commit} = Ontogen.commit(add: graph())

      assert commit.add == expected_add
      assert commit.committer == Config.user()
      assert DateTime.diff(DateTime.utc_now(), commit.time, :second) <= 1

      assert commit.speech_act.add == expected_add
      assert commit.speech_act.speaker == Config.user()
      assert DateTime.diff(DateTime.utc_now(), commit.speech_act.time, :second) <= 1

      # inserts the provenance
      assert Ontogen.prov_graph() ==
               {:ok,
                RDF.graph(
                  [
                    commit,
                    expected_add,
                    Config.user()
                  ]
                  |> Enum.map(&Grax.to_rdf!/1),
                  prefixes: ProvGraph.prefixes()
                )}
    end

    test "with explicit speech_act" do
      refute Ontogen.head()

      expected_add = speech_act().add
      committer = agent(:agent_jane)
      time = datetime()
      message = "Initial commit"

      assert {:ok,
              %Ontogen.Commit{
                parent: nil,
                add: ^expected_add,
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

      assert_repo_state(
        commit,
        graph(),
        [
          commit,
          expected_add,
          committer,
          speech_act()
        ]
        |> Enum.map(&Grax.to_rdf!/1)
      )
    end
  end

  test "subsequent commit" do
    [first_commit] = init_commit_history()

    add = RDF.graph({EX.S3, EX.p3(), "foo"})
    remove = RDF.graph(EX.S1 |> EX.p1(EX.O1))

    assert {:ok, second_commit} =
             Ontogen.commit(
               add: add,
               remove: remove,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert second_commit.parent == first_commit.__id__
    assert second_commit.add == Proposition.new!(add)
    assert second_commit.remove == Proposition.new!(remove)

    assert_repo_state(
      second_commit,
      graph() |> Graph.add(add) |> Graph.delete(remove),
      [
        first_commit,
        second_commit,
        Proposition.new!(graph()),
        Proposition.new!(add),
        Proposition.new!(remove),
        Config.user(),
        agent(:agent_jane)
      ]
      |> Enum.map(&Grax.to_rdf!/1)
    )
  end

  test "update" do
    [last_commit] = init_commit_history()

    update = [
      {EX.S3, EX.p3(), "foo"},
      EX.S2 |> EX.p2("Foo", "Bar")
    ]

    expected_update = RDF.graph([EX.S3 |> EX.p3("foo"), EX.S2 |> EX.p2("Bar")])
    expected_remove = RDF.graph(EX.S2 |> EX.p2(42))

    original_update = Proposition.new!(update)

    expected_update_proposition = Proposition.new!(expected_update)
    expected_remove_proposition = Proposition.new!(expected_remove)

    assert {:ok, new_commit} =
             Ontogen.commit(
               update: update,
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime()
             )

    assert new_commit.parent == last_commit.__id__
    assert new_commit.update == expected_update_proposition
    assert new_commit.overwrite == expected_remove_proposition
    assert new_commit.remove == nil

    assert_repo_state(
      new_commit,
      graph()
      |> Graph.add(expected_update)
      |> Graph.delete(expected_remove),
      [
        last_commit,
        new_commit,
        Proposition.new!(graph()),
        expected_update_proposition,
        expected_remove_proposition,
        original_update,
        Config.user(),
        agent(:agent_jane)
      ]
      |> Enum.map(&Grax.to_rdf!/1)
    )
  end

  test "replace (with speech_act)" do
    [last_commit] = init_commit_history()

    add = {EX.S4, EX.p4(), EX.O4}

    replace = [
      {EX.S3, EX.p3(), "foo"},
      EX.S2 |> EX.p3("Bar")
    ]

    expected_remove = RDF.graph(EX.S2 |> EX.p2(42, "Foo"))

    add_proposition = Proposition.new!(add)
    replace_proposition = Proposition.new!(replace)
    overwrite_proposition = Proposition.new!(expected_remove)

    speech_act_args = [
      add: add,
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
    assert new_commit.add == add_proposition
    assert new_commit.replace == replace_proposition
    assert new_commit.overwrite == overwrite_proposition

    assert_repo_state(
      new_commit,
      graph()
      |> Graph.add(add)
      |> Graph.add(replace)
      |> Graph.delete(expected_remove),
      [
        last_commit,
        new_commit,
        Proposition.new!(graph()),
        add_proposition,
        replace_proposition,
        overwrite_proposition,
        speech_act,
        Config.user(),
        agent(:agent_jane)
      ]
      |> Enum.map(&Grax.to_rdf!/1)
    )
  end

  describe "handling of changes that already apply" do
    test "only the real changes are committed" do
      [last_commit] = init_commit_history()

      add = [
        {EX.S3, EX.p3(), "foo"},
        # This statement was already inserted with the first commit
        EX.S1 |> EX.p1(EX.O1)
      ]

      remove = [
        EX.S2 |> EX.p2(42),
        # This statement is not present
        EX.S3 |> EX.p3(EX.O3)
      ]

      expected_add = RDF.graph(EX.S3 |> EX.p3("foo"))
      expected_remove = RDF.graph(EX.S2 |> EX.p2(42))

      expected_add_proposition = Proposition.new!(expected_add)
      expected_remove_proposition = Proposition.new!(expected_remove)

      speech_act =
        speech_act(
          add: add,
          remove: remove,
          speaker: agent(:agent_jane),
          time: datetime(),
          data_source: nil
        )

      assert {:ok, new_commit} =
               Ontogen.commit(
                 add: add,
                 remove: remove,
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.add == expected_add_proposition
      assert new_commit.remove == expected_remove_proposition
      assert new_commit.speech_act == speech_act

      assert_repo_state(
        new_commit,
        graph()
        |> Graph.add(add)
        |> Graph.delete(expected_remove),
        [
          last_commit,
          new_commit,
          speech_act,
          Proposition.new!(graph()),
          expected_add_proposition,
          expected_remove_proposition,
          Config.user(),
          agent(:agent_jane)
        ]
        |> Enum.map(&Grax.to_rdf!/1)
      )
    end

    test "with speech_act" do
      [last_commit] = init_commit_history()

      add = [
        {EX.S3, EX.p3(), "foo"},
        # This statement was already inserted with the first commit
        EX.S2 |> EX.p2("Foo")
      ]

      remove = [
        EX.S1 |> EX.p1(EX.O1),
        # This statement is not present
        EX.S3 |> EX.p3(EX.O3)
      ]

      expected_add = RDF.graph(EX.S3 |> EX.p3("foo"))
      expected_remove = RDF.graph(EX.S1 |> EX.p1(EX.O1))

      expected_add_proposition = Proposition.new!(expected_add)
      expected_remove_proposition = Proposition.new!(expected_remove)

      assert {:ok, new_commit} =
               Ontogen.commit(
                 speech_act: [
                   add: add,
                   remove: remove,
                   time: datetime()
                 ],
                 committer: agent(:agent_jane),
                 message: "Second commit",
                 time: datetime()
               )

      assert new_commit.speech_act ==
               SpeechAct.new!(
                 add: add,
                 remove: remove,
                 time: datetime()
               )

      assert new_commit.parent == last_commit.__id__
      assert new_commit.add == expected_add_proposition
      assert new_commit.remove == expected_remove_proposition

      assert_repo_state(
        new_commit,
        graph()
        |> Graph.add(add)
        |> Graph.delete(expected_remove),
        [
          last_commit,
          new_commit,
          Proposition.new!(graph()),
          expected_add_proposition,
          expected_remove_proposition,
          SpeechAct.new!(
            add: add,
            remove: remove,
            time: datetime()
          ),
          Config.user(),
          agent(:agent_jane)
        ]
        |> Enum.map(&Grax.to_rdf!/1)
      )
    end

    test "when there are no remaining changes; with on_no_effective_changes: :error" do
      [last_commit] = init_commit_history()
      {:ok, last_dataset} = Ontogen.dataset()
      {:ok, last_prov_graph} = Ontogen.prov_graph()

      assert Ontogen.commit(
               add: Proposition.graph(last_commit.add),
               committer: agent(:agent_jane),
               message: "Second commit",
               time: datetime(),
               on_no_effective_changes: :error
             ) ==
               {:error, %NoEffectiveChanges{}}

      assert_repo_state(last_commit, last_dataset, last_prov_graph)
    end
  end

  defp assert_repo_state(head, dataset, prov_graph) do
    # updates the head in the repo
    assert Ontogen.head() == head

    # updates the repo graph in the store
    assert Ontogen.repository() |> flatten_property(:head) == stored_repo()

    # inserts the statements
    assert Ontogen.dataset() == {:ok, dataset}

    # inserts the provenance
    assert Ontogen.prov_graph() == {:ok, RDF.graph(prov_graph, prefixes: ProvGraph.prefixes())}
  end
end
