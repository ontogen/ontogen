---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commit.Id]]"
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

Final version: [[ModuleDoc of Ontogen.Commit.Id]]

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

# Prompt for ModuleDoc of Ontogen.Commit.Id

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

##### `Ontogen.Commit` ![[Ontogen.Commit#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commit.Id#Context knowledge|]]


## Request

![[Ontogen.Commit.Id#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commit.Id` ![[Ontogen.Commit.Id#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commit.Id do
  import Ontogen.IdUtils

  alias Ontogen.Commit

  def generate(%Commit{} = commit) do
    {:ok, content_hash_iri(:commit, &content/1, [commit])}
  end

  def content(commit) do
    [
      if(commit.parent, do: "parent #{to_hash(commit.parent)}"),
      # TODO: Should the speech_act be part of the hash?
      if(commit.insertion, do: "insertion #{to_hash(commit.insertion)}"),
      if(commit.deletion, do: "deletion #{to_hash(commit.deletion)}"),
      if(commit.update, do: "update #{to_hash(commit.update)}"),
      if(commit.replacement, do: "update #{to_hash(commit.replacement)}"),
      if(commit.overwrite, do: "update #{to_hash(commit.overwrite)}"),
      # TODO: handle blank node agents by using the mbox instead ...
      "committer <#{to_id(commit.committer)}> #{to_timestamp(commit.time)}",
      "\n",
      commit.message
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end

```
