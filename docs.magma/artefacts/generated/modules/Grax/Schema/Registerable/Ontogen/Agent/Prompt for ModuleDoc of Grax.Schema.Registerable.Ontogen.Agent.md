---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Grax.Schema.Registerable.Ontogen.Agent]]"
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

Final version: [[ModuleDoc of Grax.Schema.Registerable.Ontogen.Agent]]

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

# Prompt for ModuleDoc of Grax.Schema.Registerable.Ontogen.Agent

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

![[Grax.Schema.Registerable.Ontogen.Agent#Context knowledge|]]


## Request

![[Grax.Schema.Registerable.Ontogen.Agent#ModuleDoc prompt task|]]

### Description of the module `Grax.Schema.Registerable.Ontogen.Agent` ![[Grax.Schema.Registerable.Ontogen.Agent#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Agent do
  @moduledoc """
  Grax schema for Ontogen Agents (`og:Agent`).

  An Ontogen agent performs `og:Activity`s on a `Ontogen.Repository`.
  """

  use Grax.Schema

  alias Ontogen.NS.Og
  alias RDF.IRI

  require Logger

  schema Og.Agent do
    property name: FOAF.name(), type: :string, required: true
    property email: Og.email(), type: :iri, required: true
  end

  def on_load(%{email: nil} = agent, _graph, _opts) do
    mbox =
      agent
      |> Grax.additional_statements()
      |> FOAF.mbox()
      |> case do
        [email] ->
          email

        [email | _] ->
          Logger.warn(
            "No unique foaf:mbox found for agent #{agent.__id__}: selected #{email} randomly"
          )

          email

        nil ->
          nil
      end

    {:ok, %__MODULE__{agent | email: mbox}}
  end

  def on_load(agent, _, _), do: {:ok, agent}

  @doc """
  Returns the email of an Ontogen agent.

  ## Example

      iex> Ontogen.Agent.build!(EX.Agent, email: ~I<mailto:agent@example.com>)
      ...> |> Ontogen.Agent.email()
      "agent@example.com"

      iex> Ontogen.Agent.build!(EX.Agent)
      ...> |> Ontogen.Agent.email()
      nil

  """
  @spec email(t()) :: String.t() | nil
  def email(%{email: %IRI{value: "mailto:" <> email}}), do: email
  def email(_), do: nil
end

```
