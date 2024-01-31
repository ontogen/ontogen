defmodule Ontogen.Action do
  @fields [:insert, :delete, :update, :replace, :overwrite]

  @doc """
  Returns a list of the action fields.

  ## Example

      iex> Ontogen.Action.fields()
      #{inspect(@fields)}

  """
  @spec fields :: list(atom)
  def fields, do: @fields
end
