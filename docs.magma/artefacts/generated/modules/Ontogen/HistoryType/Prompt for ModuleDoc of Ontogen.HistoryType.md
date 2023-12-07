---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.HistoryType]]"
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

Final version: [[ModuleDoc of Ontogen.HistoryType]]

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

# Prompt for ModuleDoc of Ontogen.HistoryType

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

##### `Ontogen.HistoryType.Raw` ![[Ontogen.HistoryType.Raw#Description|]]

##### `Ontogen.HistoryType.Native` ![[Ontogen.HistoryType.Native#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.HistoryType#Context knowledge|]]


## Request

![[Ontogen.HistoryType#ModuleDoc prompt task|]]

### Description of the module `Ontogen.HistoryType` ![[Ontogen.HistoryType#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.HistoryType do
  alias RDF.{IRI, Statement, Graph}

  @type subject_type :: :dataset | :graph | :resource | :statement
  @type subject ::
          {:dataset, IRI.t()}
          | {:graph, IRI.t()}
          | {:resource, IRI.t()}
          | {:statement, Statement.t()}

  @callback history(history_graph :: Graph.t(), subject, opts :: keyword) ::
              {:ok, list} | {:error, any}

  @default_history_type Ontogen.HistoryType.Native

  def history(history_graph, subject, opts \\ []) do
    with {:ok, history_type, opts} <- history_type(opts) do
      history_type.history(history_graph, subject, opts)
    end
  end

  defp history_type(opts) do
    case Keyword.pop(opts, :type) do
      {nil, opts} -> {:ok, @default_history_type, opts}
      {:native, opts} -> {:ok, Ontogen.HistoryType.Native, opts}
      {:raw, opts} -> {:ok, Ontogen.HistoryType.Raw, opts}
      {history_type, opts} when is_atom(history_type) -> {:ok, history_type, opts}
      {invalid, _} -> {:error, "invalid history type: #{inspect(invalid)}"}
    end
  end
end

```
