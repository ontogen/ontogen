defmodule Ontogen.ConfigHelper do
  alias Ontogen.{Bog, Config}
  alias Ontogen.NS.Og
  alias RDF.Graph

  def configured_store_adapter do
    "config/ontogen/test/service.bog.ttl"
    |> RDF.read_file!()
    |> Graph.query([
      {:_service, Og.serviceStore(), :_store},
      {:_store, Bog.this(), :store_adapter_class?}
    ])
    |> case do
      [%{store_adapter_class: store_adapter_class}] ->
        Grax.schema(store_adapter_class)
    end
  end

  def service_structure_graph do
    Config.Loader.service_structure()
    |> Bog.precompile!()
  end
end
