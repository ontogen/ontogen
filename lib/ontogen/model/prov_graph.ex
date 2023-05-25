defmodule Ontogen.ProvGraph do
  use Grax.Schema

  alias Ontogen.NS.Og

  schema Og.ProvGraph < PROV.Bundle do
  end
end
