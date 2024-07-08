defmodule Ontogen.Store.Adapters.Fuseki do
  use Grax.Schema

  alias Ontogen.NS.{Og, OgA}

  schema OgA.Fuseki < Ontogen.Store do
    # overrides the port default value
    property port: Og.storeEndpointPort(), type: :integer, default: 3030
    property dataset: Og.storeEndpointDataset(), type: :string, required: true

    # make these properties no longer required
    property query_endpoint: Og.storeQueryEndpoint(), type: :iri, required: false
    property update_endpoint: Og.storeUpdateEndpoint(), type: :iri, required: false
    property graph_store_endpoint: Og.storeGraphStoreEndpoint(), type: :iri, required: false
  end

  use Ontogen.Store.Adapter,
    name: :fuseki,
    query_endpoint_path: "query",
    update_endpoint_path: "update",
    graph_store_endpoint_path: "data"
end
