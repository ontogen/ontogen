---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.Commit.Update]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.Commit.Update]]

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

# Prompt for ModuleDoc of Ontogen.Commands.Commit.Update

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

##### `Ontogen.Commands.Commit` ![[Ontogen.Commands.Commit#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commands.Commit.Update#Context knowledge|]]


## Request

![[Ontogen.Commands.Commit.Update#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.Commit.Update` ![[Ontogen.Commands.Commit.Update#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.Commit.Update do
  alias Ontogen.{Proposition, Repository}
  alias Ontogen.NS.Og
  alias RDF.NTriples

  def build(repo, commit) do
    # TODO: use prefix helper
    # TODO: use SPARQL.Client.update_data
    # TODO: validate consistency of current HEAD with commit.parent
    #       or use a WHERE clause to fetch the current head?
    {:ok,
     """
     PREFIX og: <#{Og.__base_iri__()}>
     DELETE DATA {
       #{head(repo, commit.parent)}
       #{dataset_changes(repo, commit.deletion)}
       #{dataset_changes(repo, commit.overwrite)}
     } ;
     INSERT DATA {
       #{head(repo, commit.__id__)}
       #{dataset_changes(repo, commit.insertion)}
       #{dataset_changes(repo, commit.update)}
       #{dataset_changes(repo, commit.replacement)}
       #{provenance(repo, commit)}
       #{provenance(repo, commit.speech_act)}
     }
     """}
  end

  defp head(_, nil), do: ""

  defp head(repo, head) do
    "GRAPH <#{Repository.graph_id(repo)}> { <#{Repository.dataset_graph_id(repo)}> og:head <#{head}> }"
  end

  defp dataset_changes(_, nil), do: ""

  defp dataset_changes(repo, proposition) do
    do_dataset_changes(repo, proposition |> Proposition.graph() |> triples())
  end

  defp do_dataset_changes(repo, data) do
    "GRAPH <#{Repository.dataset_graph_id(repo)}> { #{data} }"
  end

  defp provenance(_, nil), do: ""

  defp provenance(repo, element) do
    "GRAPH <#{Repository.prov_graph_id(repo)}> { #{element |> Grax.to_rdf!() |> triples()} }"
  end

  defp triples(nil), do: ""
  defp triples(data), do: NTriples.write_string!(data)
end

```
