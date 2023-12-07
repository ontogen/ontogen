---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Grax.Schema.Registerable.Ontogen.SpeechAct]]"
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

Final version: [[ModuleDoc of Grax.Schema.Registerable.Ontogen.SpeechAct]]

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

# Prompt for ModuleDoc of Grax.Schema.Registerable.Ontogen.SpeechAct

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

![[Grax.Schema.Registerable.Ontogen.SpeechAct#Context knowledge|]]


## Request

![[Grax.Schema.Registerable.Ontogen.SpeechAct#ModuleDoc prompt task|]]

### Description of the module `Grax.Schema.Registerable.Ontogen.SpeechAct` ![[Grax.Schema.Registerable.Ontogen.SpeechAct#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.SpeechAct do
  #  Magma.moduledoc(
  #    "Encapsulates the act of uttering RDF statements, capturing both the statements and their associated metadata."
  #  )
  use Magma

  #  @moduledoc """
  #  The utterance of a set of RDF statements, i.e. a RDF graph or dataset.
  #
  #  Note, that the preferred method for creating `Ontogen.SpeechAct`s is the
  #  `Ontogen.Commands.CreateSpeechAct.call/1` function, which uses defaults
  #  according to the local config, e.g. the configured agent as the default
  #  speaker agent.
  #  """

  #  @moduledoc """
  #  Represents utterances of RDF statements along with their context.
  #  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Proposition, Changeset}
  alias Ontogen.SpeechAct.Id
  alias RDF.Graph

  schema Og.SpeechAct do
    link insertion: Og.insertion(), type: Proposition, depth: +1
    link deletion: Og.deletion(), type: Proposition, depth: +1
    link update: Og.update(), type: Proposition, depth: +1
    link replacement: Og.replacement(), type: Proposition, depth: +1

    property time: PROV.endedAtTime(), type: :date_time, required: true
    link speaker: Og.speaker(), type: Ontogen.Agent, depth: +1
    # TODO: Is this type too strict?
    link data_source: Og.dataSource(), type: DCAT.Dataset, depth: 0
  end

  def new(%Changeset{} = changeset, args) do
    with {:ok, speech_act} <- build(RDF.bnode(:tmp), args),
         speech_act = struct(speech_act, Map.from_struct(changeset)),
         {:ok, id} <- Id.generate(speech_act) do
      speech_act
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  def new!(changeset, args) do
    case new(changeset, args) do
      {:ok, speech_act} -> speech_act
      {:error, error} -> raise error
    end
  end

  def new(args) do
    with {:ok, changeset, args} <- Changeset.extract(args) do
      new(changeset, args)
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, speech_act} -> speech_act
      {:error, error} -> raise error
    end
  end

  def validate(speech_act) do
    # TODO: add more validations. eg. some speaker or data_source must be specified in some form
    Grax.validate(speech_act)
  end

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      # TODO: use RDF typing opt-out of Grax when available
      |> Graph.delete({id, RDF.type(), Og.SpeechAct})
    }
  end
end

```
