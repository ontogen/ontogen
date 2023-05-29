defmodule Ontogen.Repository do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Dataset, ProvGraph}

  schema Og.Repository do
    link dataset: Og.dataset(), type: Dataset, required: true
    link prov_graph: Og.provGraph(), type: ProvGraph, required: true
  end
end
