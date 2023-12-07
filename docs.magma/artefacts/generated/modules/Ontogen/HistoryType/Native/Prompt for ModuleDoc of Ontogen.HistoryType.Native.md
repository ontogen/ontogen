---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.HistoryType.Native]]"
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

Final version: [[ModuleDoc of Ontogen.HistoryType.Native]]

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

# Prompt for ModuleDoc of Ontogen.HistoryType.Native

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

##### `Ontogen.HistoryType` ![[Ontogen.HistoryType#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.HistoryType.Native#Context knowledge|]]


## Request

![[Ontogen.HistoryType.Native#ModuleDoc prompt task|]]

### Description of the module `Ontogen.HistoryType.Native` ![[Ontogen.HistoryType.Native#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.HistoryType.Native do
  @behaviour Ontogen.HistoryType

  alias Ontogen.NS.Og
  alias Ontogen.Commit
  alias RDF.Graph

  import RDF.Utils, only: [map_while_ok: 2]

  @impl true
  def history(history_graph, _, _opts \\ []) do
    with {:ok, commits} <-
           history_graph
           |> Graph.descriptions()
           |> Enum.filter(&commit?/1)
           |> map_while_ok(&Commit.load(history_graph, &1.subject)) do
      {:ok, Enum.sort_by(commits, & &1.time, {:desc, DateTime})}
    end
  end

  defp commit?(description), do: !!description[Og.committer()]
end

```
