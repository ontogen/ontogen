---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Grax.Schema.Registerable.Ontogen.ProvGraph]]"
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

Final version: [[ModuleDoc of Grax.Schema.Registerable.Ontogen.ProvGraph]]

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

# Prompt for ModuleDoc of Grax.Schema.Registerable.Ontogen.ProvGraph

## System prompt

![[Magma.system.config#Persona|]]

![[ModuleDoc.artefact.config#System prompt|]]

### Context knowledge

The following sections contain background knowledge you need to be aware of, but which should NOT necessarily be covered in your response as it is documented elsewhere. Only mention absolutely necessary facts from it. Use a reference to the source if necessary.

![[Magma.system.config#Context knowledge|]]

#### Description of the Ontogen project ![[Project#Description|]]

![[Module.matter.config#Context knowledge|]]

#### Peripherally relevant modules

##### `Grax` ![[Grax#Description|]]

##### `Grax.Schema` ![[Grax.Schema#Description|]]

##### `Grax.Schema.Registerable` ![[Grax.Schema.Registerable#Description|]]

##### `Grax.Schema.Registerable.Ontogen` ![[Grax.Schema.Registerable.Ontogen#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Grax.Schema.Registerable.Ontogen.ProvGraph#Context knowledge|]]


## Request

![[Grax.Schema.Registerable.Ontogen.ProvGraph#ModuleDoc prompt task|]]

### Description of the module `Grax.Schema.Registerable.Ontogen.ProvGraph` ![[Grax.Schema.Registerable.Ontogen.ProvGraph#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.ProvGraph do
  @moduledoc """
  Grax schema for the metadata about the provenance graph of a dataset.
  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias RDF.PrefixMap

  @prefixes RDF.standard_prefixes() |> PrefixMap.merge!(rtc: RTC, og: Og)

  # TODO: < DCAT.Dataset
  schema Og.ProvGraph < PROV.Bundle do
  end

  def prefixes, do: @prefixes
end

```
