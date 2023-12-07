---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen]]"
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

Final version: [[ModuleDoc of Ontogen]]

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

# Prompt for ModuleDoc of Ontogen

## System prompt

![[Magma.system.config#Persona|]]

![[ModuleDoc.artefact.config#System prompt|]]

### Context knowledge

The following sections contain background knowledge you need to be aware of, but which should NOT necessarily be covered in your response as it is documented elsewhere. Only mention absolutely necessary facts from it. Use a reference to the source if necessary.

![[Magma.system.config#Context knowledge|]]

#### Description of the Ontogen project ![[Project#Description|]]

![[Module.matter.config#Context knowledge|]]

#### Peripherally relevant modules

##### `Ontogen.Commit` ![[Ontogen.Commit#Description|]]

##### `Ontogen.SpeechAct` ![[Ontogen.SpeechAct#Description|]]

##### `Ontogen.InvalidSpeechActError` ![[Ontogen.InvalidSpeechActError#Description|]]

##### `Ontogen.Store` ![[Ontogen.Store#Description|]]

##### `Ontogen.InvalidCommitError` ![[Ontogen.InvalidCommitError#Description|]]

##### `Ontogen.QueryUtils` ![[Ontogen.QueryUtils#Description|]]

##### `Ontogen.Local` ![[Ontogen.Local#Description|]]

##### `Ontogen.Agent` ![[Ontogen.Agent#Description|]]

##### `Ontogen.InvalidChangesetError` ![[Ontogen.InvalidChangesetError#Description|]]

##### `Ontogen.IdUtils` ![[Ontogen.IdUtils#Description|]]

##### `Ontogen.IdGenerationError` ![[Ontogen.IdGenerationError#Description|]]

##### `Ontogen.Utils` ![[Ontogen.Utils#Description|]]

##### `Ontogen.Dataset` ![[Ontogen.Dataset#Description|]]

##### `Ontogen.Repository` ![[Ontogen.Repository#Description|]]

##### `Ontogen.NS` ![[Ontogen.NS#Description|]]

##### `Ontogen.InvalidRepoSpecError` ![[Ontogen.InvalidRepoSpecError#Description|]]

##### `Ontogen.ProvGraph` ![[Ontogen.ProvGraph#Description|]]

##### `Ontogen.HistoryType` ![[Ontogen.HistoryType#Description|]]

##### `Ontogen.Changeset` ![[Ontogen.Changeset#Description|]]

##### `Ontogen.Proposition` ![[Ontogen.Proposition#Description|]]

##### `Ontogen.IdSpec` ![[Ontogen.IdSpec#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen#Context knowledge|]]


## Request

![[Ontogen#ModuleDoc prompt task|]]

### Description of the module `Ontogen` ![[Ontogen#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen do
  use Magma

  defdelegate create_repo(repo_spec, opts \\ []), to: Ontogen.Local.Repo, as: :create

  # TODO: Move this to Ontogen.Local? It's using the local config ...
  defdelegate speech_act(args), to: Ontogen.Commands.CreateSpeechAct, as: :call
  defdelegate speech_act!(args), to: Ontogen.Commands.CreateSpeechAct, as: :call!
end

```
