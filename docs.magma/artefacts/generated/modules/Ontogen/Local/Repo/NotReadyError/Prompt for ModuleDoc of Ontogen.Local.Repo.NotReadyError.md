---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Local.Repo.NotReadyError]]"
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

Final version: [[ModuleDoc of Ontogen.Local.Repo.NotReadyError]]

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

# Prompt for ModuleDoc of Ontogen.Local.Repo.NotReadyError

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

##### `Ontogen.Local` ![[Ontogen.Local#Description|]]

##### `Ontogen.Local.Repo` ![[Ontogen.Local.Repo#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Local.Repo.NotReadyError#Context knowledge|]]


## Request

![[Ontogen.Local.Repo.NotReadyError#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Local.Repo.NotReadyError` ![[Ontogen.Local.Repo.NotReadyError#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Local.ConfigError do
  @moduledoc """
  Raised on errors with `Ontogen.Local.Config`.
  """
  defexception [:file, :reason]

  def message(%{file: nil, reason: :missing}) do
    "No local config file found"
  end

  def message(%{file: nil, reason: reason}) do
    "Invalid local config: #{inspect(reason)}"
  end

  def message(%{file: file, reason: reason}) do
    "Invalid local config file #{file}: #{inspect(reason)}"
  end
end

defmodule Ontogen.InvalidRepoSpecError do
  @moduledoc """
  Raised when the repo spec for the creation of a `Ontogen.Local.Repo`
  is invalid.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid repo spec: #{reason}"
  end
end

defmodule Ontogen.InvalidCommitError do
  @moduledoc """
  Raised on invalid `Ontogen.Commit` args.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid commit: #{reason}"
  end
end

defmodule Ontogen.InvalidSpeechActError do
  @moduledoc """
  Raised on invalid `Ontogen.SpeechAct` args.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid speech act: #{reason}"
  end
end

defmodule Ontogen.InvalidChangesetError do
  @moduledoc """
  Raised on invalid `Ontogen.Changeset` args.
  """
  defexception [:reason]

  def message(%{reason: :empty}) do
    "Invalid changeset: no changes provided"
  end

  def message(%{reason: reason}) do
    "Invalid changeset: #{reason}"
  end
end

defmodule Ontogen.IdGenerationError do
  @moduledoc """
  Raised on failing id generations.
  """
  defexception [:schema, :reason]

  def message(%{schema: nil, reason: reason}) do
    "Unable to generate id: #{reason}"
  end

  def message(%{schema: schema, reason: reason}) do
    "Unable to generate id for #{schema}: #{reason}"
  end
end

defmodule Ontogen.Local.Repo.NotReadyError do
  @moduledoc """
  Raised when trying to perform an operation on a repo when it is not ready,
  i.e. not connected with a repository in the local store.
  """
  defexception [:operation]

  def message(%{operation: operation}) do
    "Unable to perform #{inspect(operation)}. Repo not ready."
  end
end

```
