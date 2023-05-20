defmodule Ontogen.Store do
  use Grax.Schema

  alias Ontogen.NS.Ogc

  schema Ogc.Store do
    property query_endpoint: Ogc.queryEndpoint(), type: :string, required: true
    property update_endpoint: Ogc.updateEndpoint(), type: :string
    property graph_store_endpoint: Ogc.graphStoreEndpoint(), type: :string
  end
end
