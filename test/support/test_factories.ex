defmodule Ontogen.TestFactories do
  @moduledoc """
  Test factories.
  """

  use RDF

  alias Ontogen.{Agent, Store}
  alias Ontogen.Local.Config

  def local_config_attrs(attrs \\ []) do
    [
      agent: Keyword.get(attrs, :agent, agent()),
      store: Keyword.get(attrs, :store, store())
    ]
    |> Keyword.merge(attrs)
  end

  def agent_attrs(attrs \\ []) do
    [
      name: "John Doe",
      mbox: ~I<mailto:john.doe@example.com>
    ]
    |> Keyword.merge(attrs)
  end

  def store_attrs(attrs \\ []) do
    [
      query_endpoint: "http://localhost:1234/query",
      update_endpoint: "http://localhost:1234/update",
      graph_store_endpoint: "http://localhost:1234/store"
    ]
    |> Keyword.merge(attrs)
  end

  def local_config(id \\ RDF.bnode("_LocalConfig"), attrs \\ [])

  def local_config(attrs, _) when is_list(attrs) do
    Config.Loader.node() |> local_config(attrs)
  end

  def local_config(id, attrs) do
    Config.build!(id, local_config_attrs(attrs))
  end

  def agent(id \\ ~I<http://example.com/Agent>, attrs \\ []) do
    Agent.build!(id, agent_attrs(attrs))
  end

  def store(id \\ ~I<http://example.com/Store>, attrs \\ []) do
    {store_type, attrs} = Keyword.pop(attrs, :type)
    store(store_type, id, attrs)
  end

  def store(nil, id, attrs), do: store(Store.Oxigraph, id, attrs)

  def store(store_type, id, attrs) do
    store_type.build!(id, store_attrs(attrs))
  end
end
