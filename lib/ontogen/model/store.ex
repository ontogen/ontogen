defmodule Ontogen.Store do
  @moduledoc """
  Base Grax schema for triple stores hosting an `Ontogen.Repository`.
  """

  use Grax.Schema
  use Ontogen.Bog.Referencable

  @behaviour Ontogen.Store.Adapter

  alias Ontogen.Store.GenSPARQL
  alias Ontogen.InvalidStoreEndpointError
  alias Ontogen.NS.Og

  import Ontogen.Utils, only: [bang!: 2]

  schema Og.Store do
    property query_endpoint: Og.storeQueryEndpoint(), type: :iri, required: true
    property update_endpoint: Og.storeUpdateEndpoint(), type: :iri
    property graph_store_endpoint: Og.storeGraphStoreEndpoint(), type: :iri

    property scheme: Og.storeEndpointScheme(), type: :string, default: "http"
    property host: Og.storeEndpointHost(), type: :string, default: "localhost"
    property port: Og.storeEndpointPort(), type: :integer, default: 7878
    property userinfo: Og.storeEndpointUserInfo(), type: :string
  end

  def endpoint_base(%__MODULE__{} = store) do
    {:error,
     InvalidStoreEndpointError.exception(
       "endpoint_base not supported on generic #{inspect(store)}"
     )}
  end

  def endpoint_base(%_adapter_type{host: nil} = store) do
    {:error,
     InvalidStoreEndpointError.exception("missing endpoint_base info on #{inspect(store)}")}
  end

  def endpoint_base(%_adapter_type{scheme: nil} = store) do
    {:error,
     InvalidStoreEndpointError.exception("missing endpoint_base info on #{inspect(store)}")}
  end

  def endpoint_base(%adapter_type{dataset: dataset} = store) when not is_nil(dataset) do
    with {:ok, segment} <- adapter_type.dataset_endpoint_segment(store),
         {:ok, endpoint_base} <- endpoint_base(%{store | dataset: nil}) do
      {:ok, Path.join(endpoint_base, segment)}
    end
  end

  def endpoint_base(%_adapter_type{scheme: scheme, host: host, port: port, userinfo: userinfo}) do
    {:ok, to_string(%URI{scheme: scheme, host: host, port: port, userinfo: userinfo})}
  end

  def endpoint_base!(store), do: bang!(&endpoint_base/1, [store])

  def endpoint_base_with_path(%_adapter_type{} = store, path) do
    with {:ok, endpoint_base} <- endpoint_base(store) do
      {:ok, Path.join(endpoint_base, path)}
    end
  end

  def endpoint_base_with_path!(store, path), do: bang!(&endpoint_base_with_path/2, [store, path])

  def query_endpoint(%adapter_type{query_endpoint: nil} = store_adapter),
    do: adapter_type.determine_query_endpoint(store_adapter)

  def query_endpoint(%_adapter_type{query_endpoint: query_endpoint}),
    do: {:ok, to_string(query_endpoint)}

  def query_endpoint!(store), do: bang!(&query_endpoint/1, [store])

  def update_endpoint(%adapter_type{update_endpoint: nil} = store_adapter),
    do: adapter_type.determine_update_endpoint(store_adapter)

  def update_endpoint(%_adapter_type{update_endpoint: update_endpoint}),
    do: {:ok, to_string(update_endpoint)}

  def update_endpoint!(store), do: bang!(&update_endpoint/1, [store])

  def graph_store_endpoint(%adapter_type{graph_store_endpoint: nil} = store_adapter),
    do: adapter_type.determine_graph_store_endpoint(store_adapter)

  def graph_store_endpoint(%_adapter_type{graph_store_endpoint: graph_store_endpoint}),
    do: {:ok, to_string(graph_store_endpoint)}

  def graph_store_endpoint!(store), do: bang!(&graph_store_endpoint/1, [store])

  @impl true
  def determine_query_endpoint(%__MODULE__{} = store) do
    {:error,
     InvalidStoreEndpointError.exception("undefined query_endpoint on generic #{inspect(store)}")}
  end

  @impl true
  def determine_update_endpoint(%__MODULE__{} = store) do
    {:error,
     InvalidStoreEndpointError.exception("undefined update_endpoint on generic #{inspect(store)}")}
  end

  @impl true
  def determine_graph_store_endpoint(%__MODULE__{} = store) do
    {:error,
     InvalidStoreEndpointError.exception(
       "undefined graph_store_endpoint on generic #{inspect(store)}"
     )}
  end

  @impl true
  def dataset_endpoint_segment(%__MODULE__{} = store) do
    {:error,
     InvalidStoreEndpointError.exception(
       "dataset_endpoint_segment not supported on generic #{inspect(store)}"
     )}
  end

  def dataset_endpoint_segment(%adapter_type{} = store_adapter),
    do: adapter_type.dataset_endpoint_segment(store_adapter)

  @impl true
  def handle_sparql(operation, store, graph_name, opts \\ [])

  def handle_sparql(operation, %__MODULE__{} = store, graph_name, opts) do
    GenSPARQL.handle(operation, store, graph_name, opts)
  end

  def handle_sparql(operation, %store_adapter{} = store, graph_name, opts) do
    store_adapter.handle_sparql(operation, store, graph_name, opts)
  end
end
