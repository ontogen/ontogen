defmodule Ontogen.IdUtils do
  use RDF

  alias RDF.{Dataset, IRI}

  @sha_iri_prefix "urn:hash::sha256:"

  def sha_iri_prefix, do: @sha_iri_prefix

  def hash_iri(value) do
    ~i<#{@sha_iri_prefix}#{hash(value)}>
  end

  def hash(value) do
    :crypto.hash(:sha256, value)
    |> Base.encode16(case: :lower)
  end

  def hash_from_iri(%IRI{value: @sha_iri_prefix <> hash}), do: hash
  def hash_from_iri(_), do: nil

  def dataset_hash(%RDF.Dataset{} = dataset) do
    unless Dataset.empty?(dataset) do
      dataset
      |> NQuads.write_string!()
      |> hash()
    end
  end

  def dataset_hash(statements) do
    statements
    |> RDF.dataset()
    |> dataset_hash()
  end

  def dataset_hash_iri(statements) do
    if hash = dataset_hash(statements) do
      hash_iri(hash)
    end
  end

  def content_hash_iri(type, content_fun, args) do
    content = apply(content_fun, args)

    hash_iri("#{type} #{byte_size(content)}\0#{content}")
  end

  def to_id(%{__id__: id}), do: to_id(id)
  def to_id(%IRI{} = iri), do: to_string(iri)

  def to_hash(%{__id__: id}), do: to_hash(id)
  def to_hash(%IRI{} = iri), do: hash_from_iri(iri) || raise("#{iri} is not a hash id")

  def to_timestamp(datetime) do
    "#{DateTime.to_unix(datetime)} #{Calendar.strftime(datetime, "%z")}"
  end
end
