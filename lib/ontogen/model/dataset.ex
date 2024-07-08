defmodule Ontogen.Dataset do
  @moduledoc """
  Grax schema for a `og:Dataset`.
  """

  use Grax.Schema
  use Ontogen.Bog.Referencable

  alias Ontogen.NS.Og

  schema Og.Dataset < DCAT.Dataset do
  end
end
