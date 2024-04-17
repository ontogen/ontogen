defmodule Ontogen.IdUtils do
  @moduledoc false

  use RDF

  alias RDF.{Dataset, IRI}
  alias Ontogen.IdGenerationError
  alias Ontogen.NS.Og

  @short_hash_length 10

  @sha_iri_prefix "urn:hash::sha256:"
  def sha_iri_prefix, do: @sha_iri_prefix

  def hash_iri(value) do
    ~i<#{@sha_iri_prefix}#{hash(value)}>
  end

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

  def dataset_hash_iri!(statements) do
    case dataset_hash_iri(statements) do
      {:ok, dataset_hash_iri} -> dataset_hash_iri
      {:error, error} -> raise error
    end
  end

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

  def to_timestamp(datetime) do
    "#{DateTime.to_unix(datetime)} #{Calendar.strftime(datetime, "%z")}"
  end

  def error(reason, schema \\ nil) do
    IdGenerationError.exception(schema: schema, reason: reason)
  end
end
