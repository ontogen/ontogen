---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Store.Adapter]]"
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

Final version: [[ModuleDoc of Ontogen.Store.Adapter]]

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

# Prompt for ModuleDoc of Ontogen.Store.Adapter

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

##### `Ontogen.Store` ![[Ontogen.Store#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Store.Adapter#Context knowledge|]]


## Request

![[Ontogen.Store.Adapter#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Store.Adapter` ![[Ontogen.Store.Adapter#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Store.Adapter do
  @moduledoc """
  A behaviour for SPARQL triple stores hosting an `Ontogen.Repository`.
  """

  alias Ontogen.Store
  alias RDF.{Graph, IRI}

  @type query :: String.t()
  @type update :: String.t()
  @type graph :: IRI.coercible()

  @callback query(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, SPARQL.Query.Result.t()} | {:error, any}

  @callback construct(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, Graph.t()} | {:error, any}

  @callback ask(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, boolean} | {:error, any}

  @callback describe(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, Graph.t()} | {:error, any}

  @callback insert(Store.t(), graph(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback delete(Store.t(), graph(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback update(Store.t(), graph(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback insert_data(Store.t(), graph(), Graph.t(), Keyword.t()) ::
              :ok | {:error, any}

  @callback delete_data(Store.t(), graph(), Graph.t(), Keyword.t()) ::
              :ok | {:error, any}

  @callback create(Store.t(), graph(), Keyword.t()) ::
              :ok | {:error, any}

  @callback clear(Store.t(), graph() | :all | :default | :named, Keyword.t()) ::
              :ok | {:error, any}

  @callback drop(Store.t(), graph() | :all | :default | :named, Keyword.t()) ::
              :ok | {:error, any}
end

```
