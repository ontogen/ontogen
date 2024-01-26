defmodule Ontogen.Dataset do
  @moduledoc """
  Grax schema for a `og:Dataset`.
  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.Repository

  schema Og.Dataset < DCAT.Dataset do
    link repository: Og.repository(), type: Repository
  end
end
