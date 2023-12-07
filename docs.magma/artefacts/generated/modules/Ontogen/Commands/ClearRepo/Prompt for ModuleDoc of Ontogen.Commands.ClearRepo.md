---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.ClearRepo]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.ClearRepo]]

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

# Prompt for ModuleDoc of Ontogen.Commands.ClearRepo

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

![[Ontogen.Commands.ClearRepo#Context knowledge|]]


## Request

![[Ontogen.Commands.ClearRepo#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.ClearRepo` ![[Ontogen.Commands.ClearRepo#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.ClearRepo do
  @moduledoc """
  This commands clears all contents of the current `Ontogen.Repo` and reinitializes it again.

  > #### Caution {: .error}
  >
  > This command is only for test environments.
  > Do not use this in production, unless you're really sure!
  > It will delete everything: the dataset, the history, the repo!

  """

  alias Ontogen.{Local, Store, Repository}
  alias Ontogen.Commands.CreateRepo

  def call(store) do
    :ready = Local.Repo.status()

    call(store, Local.Repo.repository())

    Local.Repo.reload()
  end

  def call(store, repository) do
    delete_repo(store, repository)

    with {:ok, repository} <- Repository.set_head(repository, nil) do
      CreateRepo.call(store, repository)
    end
  end

  def delete_repo(store, _repository) do
    # TODO: Delete only the graphs of the given repository!
    #    Store.drop(store, [repository.__id__, Repository.dataset_graph_id(repository), Repository.prov_graph_id(repository)])
    Store.drop(store, :all)
  end
end

```
