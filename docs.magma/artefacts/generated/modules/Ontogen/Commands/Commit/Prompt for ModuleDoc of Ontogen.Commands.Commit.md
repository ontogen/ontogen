---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.Commit]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.Commit]]

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

# Prompt for ModuleDoc of Ontogen.Commands.Commit

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

##### `Ontogen.Commands.Commit.Update` ![[Ontogen.Commands.Commit.Update#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commands.Commit#Context knowledge|]]


## Request

![[Ontogen.Commands.Commit#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.Commit` ![[Ontogen.Commands.Commit#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.Commit do
  alias Ontogen.{
    Local,
    Store,
    Repository,
    Dataset,
    Commit,
    Changeset,
    InvalidCommitError
  }

  alias Ontogen.Commands.{CreateSpeechAct, FetchEffectiveChangeset}
  alias Ontogen.Commands.Commit.Update
  alias RDF.IRI

  # TODO: Do we want this short-form or explicitly enforce the specification of the store?
  #  def call(repo_spec), do: call(Ontogen.Local.store(), repo_spec)

  def call(store, %Repository{} = repo, args) do
    parent_commit = parent_commit(repo.dataset)
    {no_effective_changes, args} = Keyword.pop(args, :no_effective_changes, :error)

    with {:ok, speech_act, args} <- extract_speech_act(args),
         {:ok, effective_changeset} <- FetchEffectiveChangeset.call(store, repo, speech_act),
         {:ok, commit} <-
           build_commit(
             parent_commit,
             speech_act,
             effective_changeset,
             args,
             no_effective_changes
           ),
         {:ok, update} <- Update.build(repo, commit),
         :ok <- Store.update(store, nil, update),
         {:ok, new_repo} <- Repository.set_head(repo, commit) do
      {:ok, new_repo, commit}
    end
  end

  #  def call(store, branch, changes, args) do
  #    with {:ok, speech_act} <- CreateSpeechAct.call(changes) do
  #      call(store, branch, speech_act, args)
  #    end
  #  end

  defp parent_commit(%Dataset{head: nil}), do: nil
  defp parent_commit(%Dataset{head: %IRI{} = head}), do: head
  defp parent_commit(%Dataset{head: head}), do: head.__id__

  defp build_commit(_, _, :no_effective_changes, _, :error) do
    {:error, :no_effective_changes}
  end

  defp build_commit(_, _, :no_effective_changes, _, unknown) do
    raise ArgumentError, "unknown :no_effective_changes value: #{inspect(unknown)}"
  end

  defp build_commit(parent_commit, speech_act, changeset, args, _) do
    args
    |> Keyword.put(:speech_act, speech_act)
    |> Keyword.put(:changeset, changeset)
    |> Keyword.put(:parent, parent_commit)
    |> Keyword.put_new(:committer, Local.agent())
    |> Keyword.put_new(:time, DateTime.utc_now())
    |> Commit.new()
  end

  defp extract_speech_act(args) do
    {speech_act_args, args} = Keyword.pop(args, :speech_act)

    cond do
      speech_act_args && Changeset.empty?(args) ->
        with {:ok, speech_act} <- CreateSpeechAct.call(speech_act_args) do
          {:ok, speech_act, args}
        end

      speech_act_args ->
        {:error,
         InvalidCommitError.exception(reason: "speech acts are not allowed with other changes")}

      true ->
        CreateSpeechAct.extract(args)
    end
  end
end

```
