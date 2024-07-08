defmodule Ontogen.Bog.NotMinted do
  @moduledoc """
  Raised when the salt file for a referencable is not present.
  """
  defexception [:referencable]

  alias Ontogen.Bog.Referencable

  def message(%{referencable: referencable}) do
    "No salt file #{Referencable.Id.salt_path(referencable)} found for #{inspect(referencable)}"
  end
end

defmodule Ontogen.Bog.AlreadyMinted do
  @moduledoc """
  Raised when the salt file for a referencable is not present.
  """
  defexception [:referencable]

  alias Ontogen.Bog.Referencable

  def message(%{referencable: referencable}) do
    "Salt file #{Referencable.Id.salt_path(referencable)} for #{inspect(referencable)} already exits"
  end
end
