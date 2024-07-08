defmodule Ontogen.Store.Adapters.Oxigraph do
  use Grax.Schema

  alias Ontogen.NS.{Og, OgA}

  schema OgA.Oxigraph < Ontogen.Store do
    # overrides the port default value
    property port: Og.storeEndpointPort(), type: :integer, default: 7878

    # make these properties no longer required
    property query_endpoint: Og.storeQueryEndpoint(), type: :iri, required: false
    property update_endpoint: Og.storeUpdateEndpoint(), type: :iri, required: false
    property graph_store_endpoint: Og.storeGraphStoreEndpoint(), type: :iri, required: false
  end

  use Ontogen.Store.Adapter,
    name: :oxigraph,
    query_endpoint_path: "query",
    update_endpoint_path: "update",
    graph_store_endpoint_path: "store"
end
