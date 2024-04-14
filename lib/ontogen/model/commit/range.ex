defmodule Ontogen.Commit.Range do
  defstruct [:base, :target, :commit_ids]

  alias Ontogen.{Commit, InvalidCommitRangeError}
  alias Ontogen.Commit.Range.Fetcher

  def new({base, target}), do: new(base, target)
  def new(%__MODULE__{} = range), do: {:ok, range}

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

  def new!(args) do
    case new(args) do
      {:ok, range} -> range
      {:error, error} -> raise error
    end
  end

  defp normalize(_, %Commit{__id__: id}), do: {:ok, id}
  defp normalize(_, %RDF.IRI{} = iri), do: {:ok, iri}
  defp normalize(:base, :root), do: {:ok, Commit.root()}
  defp normalize(:base, nil), do: {:ok, Commit.root()}
  defp normalize(:target, head) when head in [:head, nil], do: {:ok, :head}

  defp normalize(type, invalid),
    do:
      {:error,
       InvalidCommitRangeError.exception(
         reason: "#{inspect(invalid)} is not a valid value for #{type}"
       )}

  def extract(args) when is_list(args) do
    {base, args} = Keyword.pop(args, :base)
    {target, args} = Keyword.pop(args, :target)
    {range, args} = Keyword.pop(args, :range)

    with {:ok, range} <-
           (cond do
              (base || target) && range ->
                {:error,
                 InvalidCommitRangeError.exception(reason: "mutual exclusive arguments used")}

              range ->
                new(range)

              true ->
                new(base, target)
            end) do
      {:ok, range, args}
    end
  end

  def absolute(%__MODULE__{target: :head} = range, repository) do
    if commit = Repository.head_id(repository) do
      {:ok, %__MODULE__{range | target: commit}}
    else
      {:error, :no_head}
    end
  end

  def absolute(%__MODULE__{} = range, _), do: {:ok, range}
end
