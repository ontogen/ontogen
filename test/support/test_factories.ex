defmodule Ontogen.TestFactories do
  @moduledoc """
  Test factories.
  """

  use RDF

  alias RDF.Graph

  alias Ontogen.{
    Repository,
    Dataset,
    ProvGraph,
    Agent,
    Store,
    Proposition,
    Commit,
    SpeechAct
  }

  alias Ontogen.Changeset.Action

  alias Ontogen.TestNamespaces.EX
  @compile {:no_warn_undefined, Ontogen.TestNamespaces.EX}

  import Ontogen.IdUtils

  def id(:agent), do: ~I<http://example.com/Agent>
  def id(:agent_john), do: ~I<http://example.com/Agent/john_doe>
  def id(:agent_jane), do: ~I<http://example.com/Agent/jane_doe>
  def id(:repository), do: ~I<http://example.com/test/repo>
  def id(:repo), do: id(:repository)
  def id(:dataset), do: ~I<http://example.com/test/dataset>
  def id(:prov_graph), do: ~I<http://example.com/test/prov_graph>
  def id(:store), do: ~I<http://example.com/Store>
  def id(:proposition), do: proposition().__id__
  def id(:speech_act), do: speech_act().__id__
  def id(resource) when is_rdf_resource(resource), do: resource
  def id(iri) when is_binary(iri), do: RDF.iri(iri)

  def email(format \\ :iri)
  def email(:iri), do: ~I<mailto:john.doe@example.com>

  def datetime, do: ~U[2023-05-26 13:02:02.255559Z]

  def datetime(amount_to_add, unit \\ :second),
    do: datetime() |> DateTime.add(amount_to_add, unit)

  def statement(id) when is_integer(id) or is_atom(id) do
    {
      apply(EX, :"s#{id}", []),
      apply(EX, :"p#{id}", []),
      apply(EX, :"o#{id}", [])
    }
  end

  def statement({id1, id2})
      when (is_integer(id1) or is_atom(id1)) and (is_integer(id2) or is_atom(id2)) do
    {
      apply(EX, :"s#{id1}", []),
      apply(EX, :"p#{id2}", []),
      apply(EX, :"o#{id2}", [])
    }
  end

  def statement({id1, id2, id3} = triple)
      when (is_integer(id1) or is_atom(id1)) and
             (is_integer(id2) or is_atom(id2)) and
             (is_integer(id3) or is_atom(id3)) do
    if RDF.Triple.valid?(triple) do
      triple
    else
      {
        apply(EX, :"s#{id1}", []),
        apply(EX, :"p#{id2}", []),
        apply(EX, :"o#{id3}", [])
      }
    end
  end

  def statement(statement), do: statement

  def statements(statements) when is_list(statements) do
    Enum.flat_map(statements, fn
      statement when is_integer(statement) or is_atom(statement) or is_tuple(statement) ->
        [statement(statement)]

      statement ->
        statement |> RDF.graph() |> Graph.statements()
    end)
  end

  def empty_graph, do: RDF.graph()

  @graph [
           EX.S1 |> EX.p1(EX.O1),
           EX.S2 |> EX.p2(42, "Foo")
         ]
         |> RDF.graph()
  def graph, do: @graph

  def graph(statements, opts \\ [])

  def graph(statement, opts) when is_integer(statement) or is_atom(statement) do
    statement |> statement() |> RDF.graph(opts)
  end

  def graph(statements, opts) when is_list(statements) do
    statements |> statements() |> RDF.graph(opts)
  end

  def graph(other, opts) do
    RDF.graph(other, opts)
  end

  @subgraph [
              EX.S1 |> EX.p1(EX.O1)
            ]
            |> RDF.graph()
  def subgraph, do: @subgraph

  def agent(id \\ :agent_john, attrs \\ []) do
    id
    |> id()
    |> Agent.build!(agent_attrs(id, attrs))
  end

  def agent_attrs(agent, attrs \\ [])

  def agent_attrs(:agent_jane, attrs) do
    [
      name: "Jane Doe",
      email: ~I<mailto:jane.doe@example.com>
    ]
    |> Keyword.merge(attrs)
  end

  def agent_attrs(_, attrs) do
    [
      name: "John Doe",
      email: email()
    ]
    |> Keyword.merge(attrs)
  end

  def repository(id \\ :repository, attrs \\ []) do
    id
    |> id()
    |> Repository.new!(repository_attrs(attrs))
  end

  def repository_attrs(attrs \\ []) do
    [
      dataset: Keyword.get(attrs, :dataset, dataset()),
      prov_graph: Keyword.get(attrs, :prov_graph, prov_graph())
    ]
    |> Keyword.merge(attrs)
  end

  def dataset(id \\ :dataset, attrs \\ []) do
    id
    |> id()
    |> Dataset.build!(dataset_attrs(attrs))
  end

  def dataset_attrs(attrs \\ []) do
    [
      title: "Test dataset"
    ]
    |> Keyword.merge(attrs)
  end

  def prov_graph(id \\ :prov_graph, attrs \\ []) do
    id
    |> id()
    |> ProvGraph.build!(prov_graph_attrs(attrs))
  end

  def prov_graph_attrs(attrs \\ []) do
    []
    |> Keyword.merge(attrs)
  end

  def store(id \\ :store, attrs \\ []) do
    {store_type, attrs} = Keyword.pop(attrs, :type)
    store(store_type, id, attrs)
  end

  def store(nil, id, attrs), do: store(Store.Oxigraph, id, attrs)

  def store(store_type, id, attrs) do
    id
    |> id()
    |> store_type.build!(store_attrs(attrs))
  end

  def store_attrs(attrs \\ []) do
    [
      query_endpoint: "http://localhost:1234/query",
      update_endpoint: "http://localhost:1234/update",
      graph_store_endpoint: "http://localhost:1234/store"
    ]
    |> Keyword.merge(attrs)
  end

  def proposition(graph \\ graph()) do
    graph
    |> graph()
    |> Proposition.new!()
  end

  def changeset_attrs(attrs \\ []) do
    [
      add: graph(),
      remove: {EX.Foo, EX.bar(), 42}
    ]
    |> Keyword.merge(attrs)
  end

  def commit_changeset(attrs \\ []) do
    attrs
    |> changeset_attrs()
    |> Commit.Changeset.new!()
  end

  def speech_act_changeset(attrs \\ []) do
    attrs
    |> changeset_attrs()
    |> SpeechAct.Changeset.new!()
  end

  def speech_act(attrs \\ []) do
    attrs
    |> speech_act_attrs()
    |> SpeechAct.new!()
  end

  def speech_act_attrs(attrs \\ []) do
    [
      add: graph(),
      speaker: agent(),
      data_source: dataset(),
      time: datetime()
    ]
    |> Keyword.merge(attrs)
  end

  def commit(attrs \\ [])

  def commit(%Commit{} = commit), do: commit

  def commit(attrs) do
    {changeset, attrs} = Action.extract(attrs)

    changeset =
      if Action.empty?(changeset) do
        commit_changeset() |> Map.from_struct()
      else
        changeset
      end

    attrs
    |> Keyword.put_new(:committer, agent())
    |> Keyword.put_new(:time, datetime())
    |> Keyword.put_new(:message, "Test commit")
    |> Keyword.put_new(:changeset, changeset)
    |> Keyword.update(:speech_act, changeset |> Keyword.new() |> speech_act(), fn
      %SpeechAct{} = speech_act -> speech_act
      speech_act_attrs -> speech_act(speech_act_attrs)
    end)
    |> Commit.new!()
  end

  def commits(commits_attrs, root \\ nil) do
    {commits, _} =
      Enum.reduce(commits_attrs, {[], root || Commit.root()}, fn attrs, {commits, parent} ->
        commit =
          attrs
          |> Keyword.put(:parent, parent)
          |> Keyword.pop(:revert)
          |> case do
            {true, attrs} -> attrs |> Keyword.put_new(:commits, [1 | commits]) |> revert()
            {_, attrs} -> commit(attrs)
          end

        {[commit | commits], commit.__id__}
      end)

    commits
  end

  def revert(attrs \\ []) do
    {commits, attrs} = Keyword.pop(attrs, :commits, :head)

    {reverted_base_commit, reverted_target_commit, commits} =
      case List.wrap(commits) do
        [] ->
          {nil, nil, []}

        [:head] ->
          head = commit()
          {to_iri(head.parent), to_iri(head), [head]}

        [start, head | rest] when start in [:head, 1] ->
          {to_iri(head.parent), to_iri(head), [head | rest]}

        [number | rest] when is_integer(number) ->
          [head | _] = commits = Enum.slice(rest, 0..(number - 1))
          {to_iri(List.last(commits).parent), to_iri(head), commits}

        [single] ->
          {to_iri(single.parent), to_iri(single), [single]}

        [first | rest] ->
          {to_iri(List.last(List.wrap(rest)).parent), to_iri(first), [first | rest]}
      end

    {changeset, attrs} = Action.extract(attrs)

    changeset =
      if Action.empty?(changeset) do
        commit_changeset() |> Map.from_struct()
      else
        commits
        |> Enum.reverse()
        |> Commit.Changeset.merge()
        |> Commit.Changeset.invert()
      end

    attrs
    |> Keyword.put_new(:committer, agent())
    |> Keyword.put_new(:time, datetime())
    |> Keyword.put_new(:message, Ontogen.Operations.RevertCommand.default_message(commits))
    |> Keyword.put_new(:reverted_base_commit, reverted_base_commit)
    |> Keyword.put_new(:reverted_target_commit, reverted_target_commit)
    |> Keyword.put_new(:changeset, changeset)
    |> Commit.new!()
  end
end
