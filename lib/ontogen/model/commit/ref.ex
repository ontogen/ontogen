defmodule Ontogen.Commit.Ref do
  defstruct ref: nil, offset: 0

  alias Ontogen.InvalidCommitRefError
  alias RDF.IRI

  import Ontogen.Utils, only: [bang!: 2]
  import Ontogen.IdUtils

  @sha_iri_prefix sha_iri_prefix()

  def new(ref, offset \\ 0, opts \\ [])
  def new(@sha_iri_prefix <> _ = hash, offset, opts), do: hash |> IRI.new() |> new(offset, opts)
  def new(ref, offset, opts) when is_binary(ref), do: ref |> hash_to_iri() |> new(offset, opts)

  def new(ref, offset, opts) do
    with {:ok, ref} <- validate(%__MODULE__{ref: ref, offset: offset}) do
      {:ok, if(Keyword.get(opts, :resolve, true), do: resolve(ref), else: ref)}
    end
  end

  def new!(ref, offset \\ 0, opts \\ []), do: bang!(&new/3, [ref, offset, opts])

  def validate(%__MODULE__{offset: offset} = ref) when offset < 0 do
    {:error, InvalidCommitRefError.exception(value: "negative commit ref offset: #{ref}")}
  end

  def validate(%__MODULE__{offset: offset}) when not is_integer(offset) do
    {:error, InvalidCommitRefError.exception(value: "invalid offset: #{inspect(offset)}")}
  end

  def validate(%__MODULE__{ref: :head} = ref), do: {:ok, ref}

  def validate(%__MODULE__{ref: %IRI{value: @sha_iri_prefix <> hash}} = ref) do
    if String.length(hash) == 64 do
      {:ok, ref}
    else
      {:error, InvalidCommitRefError.exception(value: hash)}
    end
  end

  def validate(%__MODULE__{ref: ref}) do
    {:error, InvalidCommitRefError.exception(value: "invalid commit ref: #{inspect(ref)}")}
  end

  def resolve(%__MODULE__{ref: %IRI{} = iri, offset: 0}), do: iri
  def resolve(%__MODULE__{} = ref), do: ref

  def parse(string) do
    string |> String.downcase() |> do_parse()
  end

  def parse!(string), do: bang!(&parse/1, [string])

  defp do_parse("head"), do: new(:head)

  defp do_parse("head~" <> string = ref) do
    with {:ok, offset} <- parse_offset(string, ref), do: new(:head, offset)
  end

  defp do_parse(ref) do
    case String.split(ref, "~") do
      [hash] -> new(hash)
      [hash, offset] -> with {:ok, offset} <- parse_offset(offset, ref), do: new(hash, offset)
    end
  end

  defp parse_offset(string, ref) do
    case Integer.parse(string, 10) do
      {offset, ""} -> {:ok, offset}
      _ -> {:error, InvalidCommitRefError.exception(value: "invalid commit ref: " <> ref)}
    end
  end

  def shift(ref, shift \\ 1)
  def shift(hash, shift) when is_binary(hash), do: hash |> hash_to_iri() |> shift(shift)
  def shift(%IRI{} = iri, shift), do: %__MODULE__{ref: iri} |> shift(shift)

  def shift(%__MODULE__{offset: offset} = ref, shift) when is_integer(shift) do
    %__MODULE__{ref | offset: offset + shift} |> validate()
  end

  def shift!(ref, shift), do: bang!(&shift/2, [ref, shift])

  def to_string(%__MODULE__{ref: :head, offset: 0}), do: "HEAD"
  def to_string(%__MODULE__{ref: :head, offset: offset}), do: "HEAD~#{offset}"
  def to_string(%__MODULE__{ref: %IRI{value: @sha_iri_prefix <> hash}}), do: hash

  def to_string(%__MODULE__{ref: %IRI{value: @sha_iri_prefix <> hash}, offset: offset}),
    do: "#{hash}~#{offset}"

  defimpl String.Chars do
    def to_string(ref), do: Ontogen.Commit.Ref.to_string(ref)
  end
end
