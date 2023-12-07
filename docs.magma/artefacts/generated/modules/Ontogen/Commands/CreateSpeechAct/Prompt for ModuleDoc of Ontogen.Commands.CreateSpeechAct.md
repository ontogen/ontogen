---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.CreateSpeechAct]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.CreateSpeechAct]]

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

# Prompt for ModuleDoc of Ontogen.Commands.CreateSpeechAct

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

![[Ontogen.Commands.CreateSpeechAct#Context knowledge|]]


## Request

![[Ontogen.Commands.CreateSpeechAct#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.CreateSpeechAct` ![[Ontogen.Commands.CreateSpeechAct#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.CreateSpeechAct do
  @moduledoc """
  Creates a `Ontogen.SpeechAct` using defaults from the `Ontogen.Local.Config`.
  """

  alias Ontogen.{Local, SpeechAct, Changeset, Utils}

  # TODO: find a better which doesn't require keeping this in-sync manually
  @args_keys Changeset.keys() ++ [:speaker, :speech_act_time, :data_source]
  @shared_args [:time, :committer]

  def call(%SpeechAct{} = speech_act) do
    Grax.validate(speech_act)
  end

  def call(args) do
    {commit_args, args} = Utils.extract_args(args, @shared_args)
    {speech_act_time, args} = Keyword.pop(args, :speech_act_time)

    args
    # TODO: only add when no other responsible agent is specified in any other way
    |> Keyword.put_new(
      :speaker,
      Keyword.get_lazy(commit_args, :committer, fn -> Local.agent() end)
    )
    |> Keyword.put(
      :time,
      speech_act_time || Keyword.get_lazy(commit_args, :time, fn -> DateTime.utc_now() end)
    )
    |> SpeechAct.new()
  end

  def call!(args) do
    case call(args) do
      {:ok, speech_act} -> speech_act
      {:error, error} -> raise error
    end
  end

  def extract(args) do
    {speech_act_args, args} = extract_args(args)

    with {:ok, speech_act} <- call(speech_act_args) do
      {:ok, speech_act, args}
    end
  end

  defp extract_args(args) do
    Utils.extract_args(args, @args_keys, @shared_args)
  end
end

```
