defmodule Ontogen.TestFactories do
  @moduledoc """
  Test factories.
  """

  use RDF

  alias Ontogen.{
    Repository,
    Dataset,
    ProvGraph,
    Agent,
    Store,
    Expression,
    EffectiveExpression,
    Utterance
  }

  alias Ontogen.Local.Config

  alias Ontogen.TestNamespaces.EX
  @compile {:no_warn_undefined, Ontogen.TestNamespaces.EX}

  def id(:config), do: RDF.bnode("_LocalConfig")
  def id(:agent), do: ~I<http://example.com/Agent>
  def id(:agent_john), do: ~I<http://example.com/Agent/john_doe>
  def id(:agent_jane), do: ~I<http://example.com/Agent/jane_doe>
  def id(:repository), do: ~I<http://example.com/test/repo>
  def id(:repo), do: id(:repository)
  def id(:dataset), do: ~I<http://example.com/test/dataset>
  def id(:prov_graph), do: ~I<http://example.com/test/prov_graph>
  def id(:store), do: ~I<http://example.com/Store>
  def id(:expression), do: expression().__id__
  def id(:effective_expression), do: effective_expression().__id__
  def id(:utterance), do: utterance().__id__
  def id(resource) when is_rdf_resource(resource), do: resource
  def id(iri) when is_binary(iri), do: RDF.iri(iri)

  def datetime, do: ~U[2023-05-26 13:02:02.255559Z]

  def local_config(id \\ :config, attrs \\ [])

  def local_config(attrs, _) when is_list(attrs) do
    Config.Loader.node() |> local_config(attrs)
  end

  def local_config(id, attrs) do
    id
    |> id()
    |> Config.build!(local_config_attrs(attrs))
  end

  def local_config_attrs(attrs \\ []) do
    [
      agent: Keyword.get(attrs, :agent, agent()),
      store: Keyword.get(attrs, :store, store())
    ]
    |> Keyword.merge(attrs)
  end

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
      email: ~I<mailto:john.doe@example.com>
    ]
    |> Keyword.merge(attrs)
  end

  def repository(id \\ :repository, attrs \\ []) do
    id
    |> id()
    |> Repository.build!(repository_attrs(attrs))
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

  @graph [
           EX.S1 |> EX.p1(EX.O1),
           EX.S2 |> EX.p2(42, "Foo")
         ]
         |> RDF.graph()
  def graph, do: @graph

  @subgraph [
              EX.S1 |> EX.p1(EX.O1)
            ]
            |> RDF.graph()
  def subgraph, do: @subgraph

  def expression(graph \\ graph()) do
    graph
    |> RDF.graph()
    |> Expression.new!()
  end

  def effective_expression do
    EffectiveExpression.new!(expression(), subgraph())
  end

  def utterance(attrs \\ []) do
    attrs
    |> utterance_attrs()
    |> Utterance.new!()
  end

  def utterance_attrs(attrs \\ []) do
    [
      insertion: graph(),
      speaker: agent(),
      data_source: dataset(),
      time: datetime()
    ]
    |> Keyword.merge(attrs)
  end
end
