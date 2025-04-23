defmodule Ontogen.Dataset do
  @moduledoc """
  Grax schema for a `og:Dataset`.
  """

  use Grax.Schema
  use Mud.Referencable

  alias Ontogen.NS.Og

  schema Og.Dataset < Gno.Dataset do
  end
end
