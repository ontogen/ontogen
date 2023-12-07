---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Grax.Schema.Registerable.Ontogen.Local.Config]]"
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

Final version: [[ModuleDoc of Grax.Schema.Registerable.Ontogen.Local.Config]]

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

# Prompt for ModuleDoc of Grax.Schema.Registerable.Ontogen.Local.Config

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

##### `Grax.Schema.Registerable.Ontogen.Local` ![[Grax.Schema.Registerable.Ontogen.Local#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Grax.Schema.Registerable.Ontogen.Local.Config#Context knowledge|]]


## Request

![[Grax.Schema.Registerable.Ontogen.Local.Config#ModuleDoc prompt task|]]

### Description of the module `Grax.Schema.Registerable.Ontogen.Local.Config` ![[Grax.Schema.Registerable.Ontogen.Local.Config#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Local.Config do
  @default_load_paths [
    # TODO: "[path]/etc/ontogen_config.ttl",
    "~/.ontogen_config.ttl",
    ".ontogen/config.ttl",
    ".ontogen_config.ttl"
  ]

  @moduledoc """
  Struct and OTP Agent for the local runtime configuration.

  The configuration is created by merging the graphs from a list RDF files
  from a load path, which can be specified in this order of precedence:

  - `:config_load_paths` argument passed as `start_args` to the application
  - `:config_load_paths` option of the `:ontogen` application configuration
  - `default_load_paths/0`

  Besides the full configuration

  - the default `Ontogen.Agent`, which will be implicitly used as the `prov:Agent`
    on every activity (unless another agent is specified)
  - the `Ontogen.Store`
  """

  use Grax.Schema

  alias Ontogen.NS.Ogc

  schema Ogc.Config do
    link :agent, Ogc.agent(), type: Ontogen.Agent, required: true
    link :store, Ogc.store(), type: Ontogen.Store, required: true
  end

  use Agent

  alias Ontogen.Local.Config.Loader

  @doc """
  The list of paths from which the configuration is iteratively built.

  #{Enum.map_join(@default_load_paths, "\n", &"- `#{&1}`")}
  """
  def default_load_paths, do: @default_load_paths

  def start_link(load_paths) do
    with {:ok, config} <- Loader.load_config(load_paths) do
      Agent.start_link(fn -> config end, name: __MODULE__)
    end
  end

  def config do
    Agent.get(__MODULE__, & &1)
  end

  def agent do
    Agent.get(__MODULE__, & &1.agent)
  end

  def store do
    Agent.get(__MODULE__, & &1.store)
  end

  def reload(load_paths) do
    with {:ok, config} <- Loader.load_config(load_paths) do
      Agent.update(__MODULE__, fn -> config end)
    end
  end
end

```
