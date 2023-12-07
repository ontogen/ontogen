---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.FetchDataset]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.FetchDataset]]

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

# Prompt for ModuleDoc of Ontogen.Commands.FetchDataset

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

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commands.FetchDataset#Context knowledge|]]


## Request

![[Ontogen.Commands.FetchDataset#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.FetchDataset` ![[Ontogen.Commands.FetchDataset#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.FetchDataset do
  alias Ontogen.{Store, Repository}

  def call(store, repository) do
    dataset_id = Repository.dataset_graph_id(repository)
    Store.query(store, dataset_id, query(dataset_id))
  end

  defp query(_dataset_id) do
    # TODO: use SPARQL graph protocol
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end
end

```
