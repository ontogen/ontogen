defmodule Ontogen.Store do
  use Grax.Schema

  alias Ontogen.NS.Ogc

  schema Ogc.Store do
    property query_endpoint: Ogc.queryEndpoint(), type: :string, required: true
    property update_endpoint: Ogc.updateEndpoint(), type: :string
    property graph_store_endpoint: Ogc.graphStoreEndpoint(), type: :string
  end

  def query(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.query(store, graph, query, opts)

  def construct(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.construct(store, graph, query, opts)

  def ask(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.ask(store, graph, query, opts)

  def describe(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.describe(store, graph, query, opts)

  def insert(%adapter{} = store, graph, update, opts \\ []),
    do: adapter.insert(store, graph, update, opts)

  def update(%adapter{} = store, graph, update, opts \\ []),
    do: adapter.update(store, graph, update, opts)

  def delete(%adapter{} = store, graph, update, opts \\ []),
    do: adapter.delete(store, graph, update, opts)

  def insert_data(%adapter{} = store, graph, data, opts \\ []),
    do: adapter.insert_data(store, graph, data, opts)

  def delete_data(%adapter{} = store, graph, data, opts \\ []),
    do: adapter.delete_data(store, graph, data, opts)

  def create(%adapter{} = store, graph, opts \\ []),
    do: adapter.create(store, graph, opts)

  def clear(%adapter{} = store, graph, opts \\ []),
    do: adapter.clear(store, graph, opts)

  def drop(%adapter{} = store, graph, opts \\ []),
    do: adapter.drop(store, graph, opts)

  @default_repository_preloading_depth 2

  def repository(store, repo_id, opts \\ []) do
    with {:ok, graph} <- repository_graph(store, repo_id) do
      Ontogen.Repository.load(graph, repo_id,
        depth: Keyword.get(opts, :depth, @default_repository_preloading_depth)
      )
    end
  end

  defp repository_graph(store, repo_id) do
    with {:ok, graph} <- query(store, repo_id, Ontogen.QueryUtils.graph_query()) do
      if RDF.Graph.describes?(graph, repo_id) do
        {:ok, graph}
      else
        {:error, :repo_not_found}
      end
    end
  end
end
