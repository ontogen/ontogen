---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Dataset]]"
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

Final version: [[ModuleDoc of Ontogen.Dataset]]

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

# Prompt for ModuleDoc of Ontogen.Dataset

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

![[Ontogen.Dataset#Context knowledge|]]


## Request

![[Ontogen.Dataset#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Dataset` ![[Ontogen.Dataset#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Dataset do
  @moduledoc """
  Grax schema for a `og:Dataset`.
  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Repository, Commit}

  schema Og.Dataset < DCAT.Dataset do
    # TODO: or as an inverse of Og.dataset?
    link repository: Og.repository(), type: Repository
    link head: Og.head(), type: Commit
  end

  def head_id(%__MODULE__{head: %Commit{__id__: id}}), do: id
  def head_id(%__MODULE__{head: head}), do: head

  def set_head(%__MODULE__{} = dataset, commit) do
    # TODO: update current_version to latest Revision?
    Grax.put(dataset, :head, commit)
  end
end

```
