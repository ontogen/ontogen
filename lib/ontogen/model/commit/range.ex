defmodule Ontogen.Commit.Range do
  @moduledoc """
  Struct for the specification of commit ranges ...

  Note: the commit specified as `:base` is interpreted exclusive, i.e. won't be included ...
  """

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
  defp normalize(:target, :head), do: {:ok, :head}
  defp normalize(:base, :root), do: {:ok, Commit.root()}
  defp normalize(:base, relative) when is_integer(relative) and relative > 0, do: {:ok, relative}

  defp normalize(type, invalid),
    do:
      {:error,
       InvalidCommitRangeError.exception(
         reason: "#{inspect(invalid)} is not a valid value for #{type}"
       )}

  def extract(args) when is_list(args) do
    {range, args} = Keyword.pop(args, :range)
    {base, args} = Keyword.pop(args, :base, !range && :root)
    {target, args} = Keyword.pop(args, :target, !range && :head)

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

  def absolute(%__MODULE__{target: :head, commit_ids: commit_ids}) when commit_ids in [nil, []] do
    {:error, InvalidCommitRangeError.exception(reason: :no_head)}
  end

  def absolute(%__MODULE__{target: :head, commit_ids: [head | _]} = range) do
    {:ok, %__MODULE__{range | target: head}}
  end

  def absolute(%__MODULE__{} = range), do: {:ok, range}

  def fetch(%__MODULE__{} = range, store, repository) do
    with {:ok, commit_ids, base} <- Fetcher.fetch(range, store, repository) do
      {:ok, %__MODULE__{range | commit_ids: commit_ids, base: base}}
    end
  end
end
