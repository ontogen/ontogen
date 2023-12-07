---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commit]]"
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

Final version: [[ModuleDoc of Ontogen.Commit]]

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

# Prompt for ModuleDoc of Ontogen.Commit

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

##### `Ontogen.Commit.Id` ![[Ontogen.Commit.Id#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commit#Context knowledge|]]


## Request

![[Ontogen.Commit#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commit` ![[Ontogen.Commit#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Changeset, Proposition, SpeechAct}
  alias Ontogen.Commit.Id
  alias RDF.Graph

  schema Og.Commit do
    link parent: Og.parentCommit(), type: Ontogen.Commit, depth: 0

    link speech_act: Og.speechAct(), type: SpeechAct, required: true, depth: +1

    link insertion: Og.committedInsertion(), type: Proposition, depth: +1
    link deletion: Og.committedDeletion(), type: Proposition, depth: +1
    link update: Og.committedUpdate(), type: Proposition, depth: +1
    link replacement: Og.committedReplacement(), type: Proposition, depth: +1
    link overwrite: Og.committedOverwrite(), type: Proposition, depth: +1

    link committer: Og.committer(), type: Ontogen.Agent, required: true, depth: +1
    property time: PROV.endedAtTime(), type: :date_time, required: true
    property message: Og.commitMessage(), type: :string

    #    link parent_revision: Og.parentRevision(), type: Ontogen.Revision, required: true
    #    link child_revision: Og.childRevision(), type: Ontogen.Revision, required: true
  end

  def new(args) do
    with {:ok, changeset, args} <- Changeset.extract(args),
         {:ok, commit} <- build(RDF.bnode(:tmp), args),
         commit = set_changes(commit, changeset),
         {:ok, id} <- Id.generate(commit) do
      commit
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, commit} -> commit
      {:error, error} -> raise error
    end
  end

  def empty?() do
  end

  defp set_changes(commit, %Changeset{} = changeset) do
    struct(commit, Map.from_struct(changeset))
  end

  def validate(commit) do
    # TODO: add more validations. eg. some speaker must be specified in some form
    Grax.validate(commit)
  end

  def root?(%__MODULE__{parent: nil}), do: true
  def root?(%__MODULE__{}), do: false

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      # TODO: use RDF typing opt-out of Grax when available
      |> Graph.delete({id, RDF.type(), Og.Commit})
    }
  end
end

```
