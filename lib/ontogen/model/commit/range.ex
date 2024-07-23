defmodule Ontogen.Commit.Range do
  @moduledoc """
  Struct for the specification of commit ranges ...

  Note: the commit specified as `:base` is interpreted exclusive, i.e. won't be included ...
  """

  defstruct [:base, :target, :commit_ids]

  alias Ontogen.{Commit, InvalidCommitRangeError}
  alias Ontogen.Commit.Range.Fetcher
  alias Ontogen.NS.Og
  alias RDF.IRI

  import Ontogen.Utils, only: [bang!: 2]
  import RDF.Namespace.IRI

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
      validate(%__MODULE__{base: base, target: target})
    end
  end

  def new!(args \\ []), do: bang!(&new/1, [args])
  def new!(base, target), do: bang!(&new/2, [base, target])

  defp normalize(_, %Commit{__id__: id}), do: {:ok, id}
  defp normalize(_, %RDF.IRI{} = iri), do: {:ok, iri}
  defp normalize(type, %Commit.Ref{ref: :head, offset: 0}), do: normalize(type, :head)
  defp normalize(_, %Commit.Ref{} = ref), do: Commit.Ref.validate(ref)
  defp normalize(:target, :head), do: {:ok, :head}
  defp normalize(:base, :root), do: {:ok, Commit.root()}

  defp normalize(:base, relative) when is_integer(relative) and relative > 0, do: {:ok, relative}

  defp normalize(:base, :head),
    do: {:error, InvalidCommitRangeError.exception(reason: :head_base)}

  defp normalize(type, invalid),
    do:
      {:error,
       InvalidCommitRangeError.exception(
         reason: "#{inspect(invalid)} is not a valid value for #{type}"
       )}

  def validate(%__MODULE__{
        base: %Commit.Ref{ref: ref, offset: base_offset},
        target: %Commit.Ref{ref: ref, offset: target_offset}
      })
      when base_offset <= target_offset do
    {:error, InvalidCommitRangeError.exception(reason: :target_before_base)}
  end

  def validate(%__MODULE__{} = range), do: {:ok, range}

  def parse(string, opts \\ []) do
    case String.split(string, "..") do
      [target_ref_string] ->
        target_ref_string
        |> Commit.Ref.parse()
        |> ref_as(Keyword.get(opts, :single_ref_as, :ref))

      [base_ref_string, target_ref_string] ->
        with {:ok, base} <- Commit.Ref.parse(base_ref_string),
             {:ok, target} <- Commit.Ref.parse(target_ref_string) do
          new(base, target)
        end
    end
  end

  def parse!(string, opts \\ []), do: bang!(&parse/2, [string, opts])

  defp ref_as({:error, _} = error, _), do: error
  defp ref_as({:ok, ref}, :ref), do: {:ok, ref}
  defp ref_as({:ok, target}, :target), do: new(:root, target)
  defp ref_as({:ok, base}, :base), do: new(base, :head)

  defp ref_as({:ok, target}, :single_commit_range) do
    with {:ok, base} <- Commit.Ref.shift(target) do
      new(base, target)
    end
  end

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

  def fetch(%Commit.Range{} = range, service) do
    if has_ref?(range) do
      with {:ok, chain} <- Fetcher.fetch(:head, service),
           {:ok, base, _} <- resolve_ref(range.base, chain),
           {:ok, target, chain} <- resolve_ref(range.target, chain) do
        %__MODULE__{range | target: target, base: base}
        |> update_commit_ids(chain)
      end
    else
      with {:ok, chain} <- Fetcher.fetch(range.target, service) do
        update_commit_ids(range, chain)
      end
    end
  end

  defp update_commit_ids(_range, []),
    do: {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}

  defp update_commit_ids(range, [target | _] = chain) do
    with {:ok, commit_ids, base} <- to_base(chain, range.base) do
      {:ok, %__MODULE__{range | commit_ids: commit_ids, base: base, target: target}}
    end
  end

  defp has_ref?(%{base: %Commit.Ref{}}), do: true
  defp has_ref?(%{target: %Commit.Ref{}}), do: true
  defp has_ref?(_), do: false

  defp resolve_ref(%Commit.Ref{ref: :head, offset: offset}, chain) do
    split_at_offset(chain, offset)
  end

  defp resolve_ref(%Commit.Ref{ref: iri, offset: offset}, chain) do
    case Enum.split_while(chain, &(&1 != iri)) do
      {_, []} -> {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}
      {_, chain} -> split_at_offset(chain, offset)
    end
  end

  defp resolve_ref(:head, [head | _] = chain), do: {:ok, head, chain}

  defp resolve_ref(%IRI{} = iri, chain) do
    case Enum.split_while(chain, &(&1 != iri)) do
      {_, []} -> {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}
      {_, chain} -> {:ok, iri, chain}
    end
  end

  defp resolve_ref(other, chain), do: {:ok, other, chain}

  defp split_at_offset(chain, offset) when offset == length(chain),
    do: {:ok, Commit.root(), []}

  defp split_at_offset(chain, offset) when offset > length(chain),
    do: {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}

  defp split_at_offset(chain, offset) do
    [first | _] = chain = Enum.slice(chain, offset..-1//1)
    {:ok, first, chain}
  end

  def to_base(chain, term_to_iri(Og.CommitRoot) = root), do: {:ok, chain, root}

  def to_base(chain, relative) when is_integer(relative) and relative > length(chain),
    do: {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}

  def to_base(chain, relative) when is_integer(relative) do
    case Enum.split(chain, relative) do
      {chain_to_base, []} -> {:ok, chain_to_base, Commit.root()}
      {chain_to_base, [base | _]} -> {:ok, chain_to_base, base}
    end
  end

  def to_base(chain, %IRI{} = base) do
    case Enum.split_while(chain, &(&1 != base)) do
      {_, []} -> {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}
      {chain_to_base, _} -> {:ok, chain_to_base, base}
    end
  end

  def to_base(chain, %Commit.Ref{ref: :head, offset: offset}) do
    to_base(chain, Enum.at(chain, offset))
  end
end
