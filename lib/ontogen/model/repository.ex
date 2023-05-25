defmodule Ontogen.Repository do
  use Grax.Schema

  alias Ontogen.NS.Og

  schema Og.Repository do
    link dataset: Og.dataset(), type: DCAT.Dataset, required: true
    link prov_graph: Og.provGraph(), type: Ontogen.ProvGraph, required: true
  end
end
