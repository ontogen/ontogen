---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Store]]"
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

Final version: [[ModuleDoc of Ontogen.Store]]

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

# Prompt for ModuleDoc of Ontogen.Store

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

##### `Ontogen.Store.Adapter` ![[Ontogen.Store.Adapter#Description|]]

##### `Ontogen.Store.Oxigraph` ![[Ontogen.Store.Oxigraph#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Store#Context knowledge|]]


## Request

![[Ontogen.Store#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Store` ![[Ontogen.Store#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Store do
  @moduledoc """
  Base Grax schema for triple stores hosting an `Ontogen.Repository`.

  This shouldn't be used directly. An inherited schema with an existing
   `Ontogen.Store.Adapter` implementation must be used instead.
  """

  use Grax.Schema

  alias Ontogen.NS.Ogc

  # TODO: < [SD.Service?]
  schema Ogc.Store do
    property query_endpoint: Ogc.queryEndpoint(), type: :string, required: true
    property update_endpoint: Ogc.updateEndpoint(), type: :string
    property graph_store_endpoint: Ogc.graphStoreEndpoint(), type: :string
  end

  def query(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.query(store, graph, query, opts)

  def construct(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.construct(store, graph, query, opts)

  def ask(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.ask(store, graph, query, opts)

  def describe(%adapter{} = store, graph, query, opts \\ []),
    do: adapter.describe(store, graph, query, opts)

  def insert(%adapter{} = store, graph, update, opts \\ []),
    do: adapter.insert(store, graph, update, opts)

  def update(%adapter{} = store, graph, update, opts \\ []),
    do: adapter.update(store, graph, update, opts)

  def delete(%adapter{} = store, graph, update, opts \\ []),
    do: adapter.delete(store, graph, update, opts)

  def insert_data(%adapter{} = store, graph, data, opts \\ []),
    do: adapter.insert_data(store, graph, data, opts)

  def delete_data(%adapter{} = store, graph, data, opts \\ []),
    do: adapter.delete_data(store, graph, data, opts)

  def create(%adapter{} = store, graph, opts \\ []),
    do: adapter.create(store, graph, opts)

  def clear(%adapter{} = store, graph, opts \\ []),
    do: adapter.clear(store, graph, opts)

  def drop(%adapter{} = store, graph, opts \\ []),
    do: adapter.drop(store, graph, opts)
end

```
