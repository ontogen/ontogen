defmodule Ontogen.Commit.Range do
  defstruct [:base, :target]

  alias Ontogen.{Commit, Repository}

  def new(args) when is_list(args) do
    with {:ok, range, _} <- extract(args) do
      {:ok, range}
    end
  end

  def new(base, target) do
    with {:ok, base} <- normalize(:base, base),
         {:ok, target} <- normalize(:target, target) do
      {:ok, %__MODULE__{base: base, target: target}}
    end
  end

  defp normalize(_, %Commit{__id__: id}), do: {:ok, id}
  defp normalize(_, %RDF.IRI{} = iri), do: {:ok, iri}
  defp normalize(:base, nil), do: {:ok, nil}
  defp normalize(:target, head) when head in [:head, nil], do: {:ok, :head}

  defp normalize(type, invalid),
    do: {:error, "invalid commit range value for #{type}: #{inspect(invalid)}"}

  def extract(args) when is_list(args) do
    {base, args} = Keyword.pop(args, :base)
    {target, args} = Keyword.pop(args, :target)

    with {:ok, range} <- new(base, target) do
      {:ok, range, args}
    end
  end

  def absolute(%__MODULE__{target: :head} = operation, repository) do
    if commit = Repository.head_id(repository) do
      {:ok, %__MODULE__{operation | target: commit}}
    else
      {:error, :no_head}
    end
  end

  def absolute(%__MODULE__{} = range, _), do: {:ok, range}
end
