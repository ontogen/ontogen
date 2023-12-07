---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.FetchHistory]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.FetchHistory]]

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

# Prompt for ModuleDoc of Ontogen.Commands.FetchHistory

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

##### `Ontogen.Commands` ![[Ontogen.Commands#Description|]]

##### `Ontogen.Commands.FetchHistory.Query` ![[Ontogen.Commands.FetchHistory.Query#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commands.FetchHistory#Context knowledge|]]


## Request

![[Ontogen.Commands.FetchHistory#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.FetchHistory` ![[Ontogen.Commands.FetchHistory#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.FetchHistory do
  alias Ontogen.{Store, Repository, HistoryType}
  alias Ontogen.Commands.FetchHistory.Query
  alias RDF.{Triple, Statement}

  import RDF.Guards

  def dataset(store, repository, opts \\ []) do
    call(store, repository, {:dataset, Repository.dataset_graph_id(repository)}, opts)
  end

  def resource(store, repository, resource, opts \\ []) do
    call(store, repository, {:resource, normalize_resource(resource)}, opts)
  end

  def statement(store, repository, statement, opts \\ []) do
    call(store, repository, {:statement, normalize_statement(statement)}, opts)
  end

  def call(store, repository, subject, opts \\ []) do
    with {:ok, query} <- Query.build(repository, subject, opts),
         {:ok, history_graph} <-
           Store.construct(store, Repository.prov_graph_id(repository), query, raw_mode: true) do
      HistoryType.history(history_graph, subject, opts)
    end
  end

  defp normalize_resource(resource) when is_rdf_resource(resource), do: resource
  defp normalize_resource(resource), do: RDF.iri(resource)

  defp normalize_statement({_, _, _} = triple), do: Triple.new(triple)

  defp normalize_statement({s, p}),
    do: {Statement.coerce_subject(s), Statement.coerce_predicate(p)}
end

```
