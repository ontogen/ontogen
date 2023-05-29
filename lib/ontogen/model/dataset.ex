defmodule Ontogen.Dataset do
  use Grax.Schema

  alias Ontogen.NS.Og

  schema Og.Dataset < DCAT.Dataset do
    link repository: Og.repository(), type: Ontogen.Repository
  end
end
