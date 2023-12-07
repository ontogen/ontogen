---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.NS.Ogc]]"
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

Final version: [[ModuleDoc of Ontogen.NS.Ogc]]

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

# Prompt for ModuleDoc of Ontogen.NS.Ogc

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

##### `Ontogen.NS` ![[Ontogen.NS#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.NS.Ogc#Context knowledge|]]


## Request

![[Ontogen.NS.Ogc#ModuleDoc prompt task|]]

### Description of the module `Ontogen.NS.Ogc` ![[Ontogen.NS.Ogc#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.NS do
  @moduledoc """
  `RDF.Vocabulary.Namespace`s for the used vocabularies.
  """

  use RDF.Vocabulary.Namespace

  @vocabdoc """
  The Ontogen vocabulary.

  See <https://w3id.org/ontogen/spec>
  """
  defvocab Og,
    base_iri: "https://w3id.org/ontogen#",
    file: "ontogen.ttl",
    case_violations: :fail,
    alias: [
      #      # TODO: rename to og:Dataset since we only deal with RDF dataset in Og anyway?
      #      Dataset: "RdfDataset",
      #      # TODO: rename to og:Graph since we only deal with RDF graphs in Og anyway?
      #      Graph: "RdfGraph"
    ]

  @vocabdoc """
  The Ontogen config vocabulary.
  """
  defvocab Ogc,
    base_iri: "https://w3id.org/ontogen/config#",
    file: "ontogen_config.ttl",
    case_violations: :fail
end

```
