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
end
