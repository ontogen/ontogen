---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Grax.Schema.Registerable.Ontogen.Repository]]"
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

Final version: [[ModuleDoc of Grax.Schema.Registerable.Ontogen.Repository]]

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

# Prompt for ModuleDoc of Grax.Schema.Registerable.Ontogen.Repository

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

![[Grax.Schema.Registerable.Ontogen.Repository#Context knowledge|]]


## Request

![[Grax.Schema.Registerable.Ontogen.Repository#ModuleDoc prompt task|]]

### Description of the module `Grax.Schema.Registerable.Ontogen.Repository` ![[Grax.Schema.Registerable.Ontogen.Repository#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Repository do
  @moduledoc """
  Grax schema for Ontogen repositories.
  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Dataset, ProvGraph}

  # TODO: < DCAT.Catalog?
  schema Og.Repository do
    link dataset: Og.dataset(), type: Dataset, required: true
    link prov_graph: Og.provGraph(), type: ProvGraph, required: true
  end

  def head_id(%__MODULE__{} = repo), do: Dataset.head_id(repo.dataset)

  def set_head(%__MODULE__{} = repo, :no_effective_changes), do: {:ok, repo}

  def set_head(%__MODULE__{} = repo, commit) do
    with {:ok, dataset} <- Dataset.set_head(repo.dataset, commit) do
      Grax.put(repo, :dataset, dataset)
    end
  end

  def graph_id(%__MODULE__{} = repository), do: repository.__id__
  def dataset_graph_id(%__MODULE__{dataset: dataset}), do: dataset.__id__
  def prov_graph_id(%__MODULE__{prov_graph: prov_graph}), do: prov_graph.__id__
end

```
