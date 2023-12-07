---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Local]]"
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

Final version: [[ModuleDoc of Ontogen.Local]]

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

# Prompt for ModuleDoc of Ontogen.Local

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

##### `Ontogen.Local.Repo` ![[Ontogen.Local.Repo#Description|]]

##### `Ontogen.Local.ConfigError` ![[Ontogen.Local.ConfigError#Description|]]

##### `Ontogen.Local.Config` ![[Ontogen.Local.Config#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Local#Context knowledge|]]


## Request

![[Ontogen.Local#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Local` ![[Ontogen.Local#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
# TODO: Warum eigentlich Ontogen.Local.Repo? Es handelt sich doch um einen SPARQL-Endpoint der auch entfernt sein kann ...
defmodule Ontogen.Local do
  @moduledoc """
  Interface to the local configuration and more ... TODO


  The full `Ontogen.Local.Config` ...

  """

  alias Ontogen.Local.Config

  defdelegate config, to: Config
  defdelegate agent, to: Config
  defdelegate store, to: Config
end

```
