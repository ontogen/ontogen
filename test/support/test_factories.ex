defmodule Ontogen.TestFactories do
  @moduledoc """
  Test factories.
  """

  use RDF

  alias Ontogen.{Agent, Store}
  alias Ontogen.Local.Config

  def id(resource) when is_rdf_resource(resource), do: resource
  def id(iri) when is_binary(iri), do: RDF.iri(iri)
  def id(:config), do: RDF.bnode("_LocalConfig")
  def id(:agent), do: ~I<http://example.com/Agent>
  def id(:repository), do: ~I<http://example.com/test/repo>
  def id(:repo), do: id(:repository)
  def id(:dataset), do: ~I<http://example.com/test/dataset>
  def id(:prov_graph), do: ~I<http://example.com/test/prov_graph>
  def id(:store), do: ~I<http://example.com/Store>

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

  def agent(id \\ :agent, attrs \\ []) do
    id
    |> id()
    |> Agent.build!(agent_attrs(attrs))
  end

  def agent_attrs(attrs \\ []) do
    [
      name: "John Doe",
      mbox: ~I<mailto:john.doe@example.com>
    ]
    |> Keyword.merge(attrs)
  end

  def repository(id \\ :repository, attrs \\ []) do
    id
    |> id()
    |> Ontogen.Repository.build!(repository_attrs(attrs))
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
    |> DCAT.Dataset.build!(dataset_attrs(attrs))
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
    |> Ontogen.ProvGraph.build!(prov_graph_attrs(attrs))
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
end
