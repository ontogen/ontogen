---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.IdUtils]]"
magma_generation_type: OpenAI
magma_generation_params: {"model":"gpt-4","temperature":0.6}
created_at: 2023-12-07 14:16:14
tags: [magma-vault]
aliases: []
---

**Generated results**

```dataview
TABLE
	tags AS Tags,
	magma_generation_type AS Generator,
	magma_generation_params AS Params
WHERE magma_prompt = [[]]
```

Final version: [[ModuleDoc of Ontogen.IdUtils]]

**Actions**

```button
name Execute
type command
action Shell commands: Execute: magma.prompt.exec
color blue
```
```button
name Execute manually
type command
action Shell commands: Execute: magma.prompt.exec-manual
color blue
```
```button
name Copy to clipboard
type command
action Shell commands: Execute: magma.prompt.copy
color default
```
```button
name Update
type command
action Shell commands: Execute: magma.prompt.update
color default
```

# Prompt for ModuleDoc of Ontogen.IdUtils

## System prompt

![[Magma.system.config#Persona|]]

![[ModuleDoc.artefact.config#System prompt|]]

### Context knowledge

The following sections contain background knowledge you need to be aware of, but which should NOT necessarily be covered in your response as it is documented elsewhere. Only mention absolutely necessary facts from it. Use a reference to the source if necessary.

![[Magma.system.config#Context knowledge|]]

#### Description of the Ontogen project ![[Project#Description|]]

![[Module.matter.config#Context knowledge|]]

#### Peripherally relevant modules

##### `Ontogen` ![[Ontogen#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.IdUtils#Context knowledge|]]


## Request

![[Ontogen.IdUtils#ModuleDoc prompt task|]]

### Description of the module `Ontogen.IdUtils` ![[Ontogen.IdUtils#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.IdUtils do
  use RDF

  alias RDF.{Dataset, IRI}
  alias Ontogen.IdGenerationError

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

  # TODO: use a more official way from RDF.ex when available
  def dataset_hash(%RDF.Dataset{} = dataset) do
    unless Dataset.empty?(dataset) do
      {:ok,
       dataset
       |> NQuads.write_string!()
       |> hash()}
    else
      {:error, error("empty dataset")}
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

```
