---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.RepoInfo]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.RepoInfo]]

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

# Prompt for ModuleDoc of Ontogen.Commands.RepoInfo

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

![[Ontogen.Commands.RepoInfo#Context knowledge|]]


## Request

![[Ontogen.Commands.RepoInfo#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.RepoInfo` ![[Ontogen.Commands.RepoInfo#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.RepoInfo do
  alias Ontogen.{Repository, Store}
  alias RDF.Graph

  @default_preloading_depth 2

  def call(store, repo_id, opts \\ []) do
    with {:ok, graph} <- Store.query(store, repo_id, query(repo_id)) do
      if Graph.describes?(graph, repo_id) do
        Repository.load(graph, repo_id,
          depth: Keyword.get(opts, :depth, @default_preloading_depth)
        )
      else
        {:error, :repo_not_found}
      end
    end
  end

  defp query(_repo_id) do
    # TODO: use SPARQL graph protocol
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end
end

```
