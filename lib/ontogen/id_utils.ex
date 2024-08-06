defmodule Ontogen.IdUtils do
  @moduledoc false

  use RDF

  alias RDF.{Dataset, IRI}
  alias Ontogen.IdGenerationError
  alias Ontogen.NS.Og

  import Ontogen.Utils, only: [bang!: 2]

  @short_hash_length 10

  @sha_iri_prefix "urn:hash::sha256:"
  def sha_iri_prefix, do: @sha_iri_prefix

  def hash_to_iri(hash), do: ~i<#{@sha_iri_prefix}#{hash}>

  def hash_iri(value), do: value |> hash() |> hash_to_iri()

  def hash(value) do
    :crypto.hash(:sha256, value)
    |> Base.encode16(case: :lower)
  end

  def short_hash(hash), do: String.slice(hash, 0, @short_hash_length)

  def hash_from_iri(term_to_iri(Og.CommitRoot)), do: "commit-root"
  def hash_from_iri(%IRI{value: @sha_iri_prefix <> hash}), do: hash
  def hash_from_iri(_), do: nil

  def short_hash_from_iri(%IRI{value: @sha_iri_prefix <> hash}), do: short_hash(hash)
  def short_hash_from_iri(_), do: nil

  def dataset_hash(%RDF.Dataset{} = dataset) do
    if Dataset.empty?(dataset) do
      {:error, error("empty dataset")}
    else
      {:ok, Dataset.canonical_hash(dataset)}
    end
  end

  def dataset_hash(statements) do
    statements
    |> RDF.dataset()
    |> dataset_hash()
  end

  def dataset_hash_iri(statements) do
    with {:ok, hash} <- dataset_hash(statements) do
      {:ok, hash_iri(hash)}
    end
  end

  def dataset_hash_iri!(statements), do: bang!(&dataset_hash_iri/1, [statements])

  def content_hash_iri(type, content_fun, args) do
    content = apply(content_fun, args)

    hash_iri("#{type} #{byte_size(content)}\0#{content}")
  end

  def to_iri(%{__id__: id}), do: to_iri(id)
  def to_iri(%IRI{} = iri), do: iri

  def to_id(%{__id__: id}), do: to_id(id)
  def to_id(%IRI{} = iri), do: to_string(iri)

  def to_hash(%{__id__: id}), do: to_hash(id)
  def to_hash(%IRI{} = iri), do: hash_from_iri(iri) || raise("#{iri} is not a hash id")

  def to_timestamp(%DateTime{} = datetime) do
    "#{DateTime.to_unix(datetime)} #{Calendar.strftime(datetime, "%z")}"
  end

  def to_timestamp(%NaiveDateTime{} = datetime) do
    datetime |> DateTime.from_naive!("Etc/UTC") |> to_timestamp()
  end

  def error(reason, schema \\ nil) do
    IdGenerationError.exception(schema: schema, reason: reason)
  end
end
