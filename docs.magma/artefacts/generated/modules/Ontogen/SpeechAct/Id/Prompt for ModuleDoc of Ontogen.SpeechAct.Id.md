---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.SpeechAct.Id]]"
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

Final version: [[ModuleDoc of Ontogen.SpeechAct.Id]]

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

# Prompt for ModuleDoc of Ontogen.SpeechAct.Id

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

##### `Ontogen.SpeechAct` ![[Ontogen.SpeechAct#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.SpeechAct.Id#Context knowledge|]]


## Request

![[Ontogen.SpeechAct.Id#ModuleDoc prompt task|]]

### Description of the module `Ontogen.SpeechAct.Id` ![[Ontogen.SpeechAct.Id#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.SpeechAct.Id do
  import Ontogen.IdUtils

  alias Ontogen.SpeechAct

  def generate(%SpeechAct{} = speech_act) do
    if origin = determine_origin(speech_act) do
      {:ok, content_hash_iri(:speech_act, &content/2, [speech_act, origin])}
    else
      {:error, error("origin missing", SpeechAct)}
    end
  end

  def content(speech_act, origin) do
    [
      if(speech_act.insertion, do: "insertion #{to_hash(speech_act.insertion)}"),
      if(speech_act.deletion, do: "deletion #{to_hash(speech_act.deletion)}"),
      if(speech_act.update, do: "deletion #{to_hash(speech_act.update)}"),
      if(speech_act.replacement, do: "deletion #{to_hash(speech_act.replacement)}"),
      # TODO: handle blank node agents by using the mbox instead ...
      "context <#{to_id(origin)}> #{to_timestamp(speech_act.time)}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp determine_origin(speech_act) do
    speech_act.speaker || speech_act.data_source ||
      speech_act.was_associated_with |> List.wrap() |> List.first()
  end
end

```
