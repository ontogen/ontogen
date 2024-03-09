defmodule Ontogen.Commit.Range do
  defstruct [:first, :last]

  alias Ontogen.{Commit, Repository}

  def new(args) when is_list(args) do
    with {:ok, range, _} <- extract(args) do
      {:ok, range}
    end
  end

  def new(first, last) do
    with {:ok, first} <- normalize(:first, first),
         {:ok, last} <- normalize(:last, last) do
      {:ok, %__MODULE__{first: first, last: last}}
    end
  end

  defp normalize(_, %Commit{__id__: id}), do: {:ok, id}
  defp normalize(_, %RDF.IRI{} = iri), do: {:ok, iri}
  defp normalize(:first, nil), do: {:ok, nil}
  defp normalize(:last, head) when head in [:head, nil], do: {:ok, :head}

  defp normalize(type, invalid),
    do: {:error, "invalid commit range value for #{type}: #{inspect(invalid)}"}

  def extract(args) when is_list(args) do
    {first, args} = Keyword.pop(args, :first)
    {last, args} = Keyword.pop(args, :last)

    with {:ok, range} <- new(first, last) do
      {:ok, range, args}
    end
  end

  def absolute(%__MODULE__{last: :head} = operation, repository) do
    if commit = Repository.head_id(repository) do
      {:ok, %__MODULE__{operation | last: commit}}
    else
      {:error, :no_head}
    end
  end

  def absolute(%__MODULE__{} = range, _), do: {:ok, range}
end
