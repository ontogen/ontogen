---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Store.Oxigraph]]"
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

Final version: [[ModuleDoc of Ontogen.Store.Oxigraph]]

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

# Prompt for ModuleDoc of Ontogen.Store.Oxigraph

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

![[Ontogen.Store.Oxigraph#Context knowledge|]]


## Request

![[Ontogen.Store.Oxigraph#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Store.Oxigraph` ![[Ontogen.Store.Oxigraph#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Store.Oxigraph do
  @moduledoc """
  `Ontogen.Store.Adapter` implementation for Oxigraph.
  """

  use Grax.Schema

  @behaviour Ontogen.Store.Adapter

  alias Ontogen.NS.Ogc
  alias RDF.{Graph, Description, Dataset}

  # TODO: < [SD.Service?]
  schema Ogc.OxigraphStore < Ontogen.Store do
  end

  @impl true
  def query(store, graph, query, opts \\ []),
    do: SPARQL.Client.query(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def construct(store, graph, query, opts \\ []),
    do: SPARQL.Client.construct(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def ask(store, graph, query, opts \\ []),
    do: SPARQL.Client.ask(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def describe(store, graph, query, opts \\ []),
    do: SPARQL.Client.describe(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def insert(store, graph, update, opts \\ []),
    do: SPARQL.Client.insert(update, update_endpoint(store), update_opts(opts, graph))

  @impl true
  def update(store, graph, update, opts \\ []),
    do: SPARQL.Client.update(update, update_endpoint(store), update_opts(opts, graph))

  @impl true
  def delete(store, graph, update, opts \\ []),
    do: SPARQL.Client.delete(update, update_endpoint(store), update_opts(opts, graph))

  @impl true
  def insert_data(store, graph, data, opts \\ []),
    do: data |> set_graph(graph) |> SPARQL.Client.insert_data(update_endpoint(store), opts)

  @impl true
  def delete_data(store, graph, data, opts \\ []),
    do: data |> set_graph(graph) |> SPARQL.Client.delete_data(update_endpoint(store), opts)

  @impl true
  def create(store, graph, opts \\ []),
    do: SPARQL.Client.create(update_endpoint(store), Keyword.put(opts, :graph, graph))

  @impl true
  def clear(store, graph, opts \\ []),
    do: SPARQL.Client.clear(update_endpoint(store), Keyword.put(opts, :graph, graph))

  @impl true
  def drop(store, graph, opts \\ []),
    do: SPARQL.Client.drop(update_endpoint(store), Keyword.put(opts, :graph, graph))

  defp query_opts(opts, graph) do
    opts
    |> add_graph_opt(:query, graph)
  end

  defp update_opts(opts, graph) do
    opts
    |> Keyword.put_new(:raw_mode, true)
    |> add_graph_opt(:update, graph)

    #    |> Keyword.put_new(:logger, true)
  end

  defp add_graph_opt(opts, _, nil), do: opts

  defp add_graph_opt(opts, type, graph) do
    {named_graph, opts} = Keyword.pop(opts, :named_graph, false)
    Keyword.put(opts, graph_opt(type, named_graph), graph)
  end

  defp graph_opt(:query, false), do: :default_graph
  defp graph_opt(:query, true), do: :named_graph
  defp graph_opt(:update, false), do: :using_graph
  defp graph_opt(:update, true), do: :using_named_graph

  defp set_graph(data, nil), do: data
  defp set_graph(data, :default), do: data

  defp set_graph(%Graph{} = data, graph_name),
    do: data |> Graph.change_name(graph_name) |> Dataset.new()

  defp set_graph(%Description{} = data, graph_name),
    do: data |> Graph.new(name: graph_name) |> Dataset.new()

  defp query_endpoint(%__MODULE__{query_endpoint: query_endpoint}), do: query_endpoint
  defp update_endpoint(%__MODULE__{update_endpoint: update_endpoint}), do: update_endpoint
end

```
