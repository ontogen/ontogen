---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Local.Repo]]"
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

Final version: [[ModuleDoc of Ontogen.Local.Repo]]

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

# Prompt for ModuleDoc of Ontogen.Local.Repo

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

##### `Ontogen.Local.Repo.NotReadyError` ![[Ontogen.Local.Repo.NotReadyError#Description|]]

##### `Ontogen.Local.Repo.IdFile` ![[Ontogen.Local.Repo.IdFile#Description|]]

##### `Ontogen.Local.Repo.Initializer` ![[Ontogen.Local.Repo.Initializer#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Local.Repo#Context knowledge|]]


## Request

![[Ontogen.Local.Repo#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Local.Repo` ![[Ontogen.Local.Repo#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Local.Repo do
  @moduledoc """
  A local Ontogen repo of a dataset and its provenance history.
  """

  use GenServer

  alias Ontogen.Local.Repo.{Initializer, NotReadyError}

  alias Ontogen.Commands.{
    RepoInfo,
    Commit,
    FetchEffectiveChangeset,
    FetchHistory,
    FetchDataset,
    FetchProvGraph
  }

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def store do
    GenServer.call(__MODULE__, :store)
  end

  def repository do
    GenServer.call(__MODULE__, :repository)
  end

  def dataset_info do
    GenServer.call(__MODULE__, :dataset_info)
  end

  def prov_graph_info do
    GenServer.call(__MODULE__, :prov_graph_info)
  end

  def fetch_dataset do
    # We're not performing the store access inside of the GenServer,
    # because we don't wont to block it for this potentially large read access.
    # Also, we don't to pass the potentially large data structure between processes.
    FetchDataset.call(store(), repository())
  end

  def fetch_prov_graph do
    # We're not performing the store access inside of the GenServer,
    # because we don't wont to block it for this potentially large read access.
    # Also, we don't to pass the potentially large data structure between processes.
    FetchProvGraph.call(store(), repository())
  end

  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  def create(repo_spec, opts \\ []) do
    GenServer.call(__MODULE__, {:create, repo_spec, opts})
  end

  def commit(args) do
    GenServer.call(__MODULE__, {:commit, args})
  end

  def effective_changeset(changeset) do
    GenServer.call(__MODULE__, {:effective_changeset, changeset})
  end

  def effective_changeset!(changeset) do
    case effective_changeset(changeset) do
      {:ok, changeset} -> changeset
      {:error, error} -> raise error
    end
  end

  defdelegate changes(changeset), to: __MODULE__, as: :effective_changeset
  defdelegate changes!(changeset), to: __MODULE__, as: :effective_changeset!

  def dataset_history(args \\ []) do
    GenServer.call(__MODULE__, {:dataset_history, args})
  end

  def resource_history(resource, args \\ []) do
    GenServer.call(__MODULE__, {:resource_history, resource, args})
  end

  def statement_history(statement, args \\ []) do
    GenServer.call(__MODULE__, {:statement_history, statement, args})
  end

  @doc """
  Returns the last commit of the dataset,
  which will be the basis for all other commands:

  - commits
  - etc.

  """
  # TODO: Do we really want to name this like Gits HEAD which refers to the
  # last commit of the current branch, but we don't have a current branch,
  # every branch is in a separate graph and always present
  def head do
    GenServer.call(__MODULE__, :head)
  end

  # Server (callbacks)

  @impl true
  def init(opts) do
    store = Initializer.store(opts)

    case Initializer.repository(opts) do
      {:ok, repository} ->
        IO.puts("Connected to repo #{repository.__id__}")
        {:ok, %{repository: repository, store: store, status: :ready}}

      {:error, :repo_not_defined} ->
        IO.puts("Repo not specified, you'll have to create one first.")
        {:ok, %{repository: nil, store: store, status: :no_repo}}

      {:error, :repo_not_found} ->
        IO.puts("Repo not found, you'll have to create one first.")
        {:ok, %{repository: nil, store: store, status: :no_repo}}

      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:status, _from, %{status: status} = state) do
    {:reply, status, state}
  end

  def handle_call(:store, _from, %{store: store} = state) do
    {:reply, store, state}
  end

  def handle_call({:create, repo_spec, opts}, _from, %{store: store, status: :no_repo} = state) do
    case Initializer.create_repo(store, repo_spec, opts) do
      {:ok, repo} -> {:reply, {:ok, repo}, %{state | repository: repo, status: :ready}}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:create, _, _}, _from, state) do
    {:reply, {:error, :repo_already_connected}, state}
  end

  def handle_call(operation, _from, %{status: :no_repo} = state) do
    {:reply, {:error, NotReadyError.exception(operation: operation)}, state}
  end

  def handle_call(:reload, _from, %{store: store, repository: repository} = state) do
    case RepoInfo.call(store, repository.__id__) do
      {:ok, repo} -> {:reply, {:ok, repo}, %{state | repository: repo}}
      error -> {:reply, error, state}
    end
  end

  def handle_call(:repository, _from, %{repository: repo} = state) do
    {:reply, repo, state}
  end

  def handle_call(:dataset_info, _from, %{repository: repo} = state) do
    {:reply, repo && repo.dataset, state}
  end

  def handle_call(:prov_graph_info, _from, %{repository: repo} = state) do
    {:reply, repo && repo.prov_graph, state}
  end

  def handle_call(:head, _from, %{repository: repo} = state) do
    {:reply, repo && repo.dataset.head, state}
  end

  def handle_call({:commit, args}, _from, %{repository: repo, store: store} = state) do
    case Commit.call(store, repo, args) do
      {:ok, repo, commit} -> {:reply, {:ok, commit}, %{state | repository: repo}}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:effective_changeset, changeset},
        _from,
        %{repository: repo, store: store} = state
      ) do
    case FetchEffectiveChangeset.call(store, repo, changeset) do
      {:ok, effective_changeset} -> {:reply, {:ok, effective_changeset}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:dataset_history, args}, _from, %{repository: repo, store: store} = state) do
    case FetchHistory.dataset(store, repo, args) do
      {:ok, history} -> {:reply, {:ok, history}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:resource_history, resource, args},
        _from,
        %{repository: repo, store: store} = state
      ) do
    case FetchHistory.resource(store, repo, resource, args) do
      {:ok, history} -> {:reply, {:ok, history}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:statement_history, statement, args},
        _from,
        %{repository: repo, store: store} = state
      ) do
    case FetchHistory.statement(store, repo, statement, args) do
      {:ok, history} -> {:reply, {:ok, history}, state}
      error -> {:reply, error, state}
    end
  end
end

```
