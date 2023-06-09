defmodule Ontogen.Dataset do
  @moduledoc """
  Grax schema for a `og:Dataset`.
  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Repository, Commit}

  schema Og.Dataset < DCAT.Dataset do
    link repository: Og.repository(), type: Repository
    link head: Og.head(), type: Commit
  end

  def head_id(%__MODULE__{head: %Commit{__id__: id}}), do: id
  def head_id(%__MODULE__{head: head}), do: head

  def set_head(%__MODULE__{} = dataset, commit) do
    Grax.put(dataset, :head, commit)
  end
end
