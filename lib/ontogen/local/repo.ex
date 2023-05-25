defmodule Ontogen.Local.Repo do
  @moduledoc """
  A local Ontogen repo of a dataset and its provenance history.
  """

  use GenServer

  alias Ontogen.Local.Repo.{Initializer, NotReadyError}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def create(repo_spec, opts \\ []) do
    GenServer.call(__MODULE__, {:create, repo_spec, opts})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def repository do
    GenServer.call(__MODULE__, :repository)
  end

  def dataset do
    GenServer.call(__MODULE__, :dataset)
  end

  def prov_graph do
    GenServer.call(__MODULE__, :prov_graph)
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

  def handle_call(:repository, _from, %{repository: repository} = state) do
    {:reply, repository, state}
  end

  def handle_call(:dataset, _from, %{repository: repository} = state) do
    {:reply, repository && repository.dataset, state}
  end

  def handle_call(:prov_graph, _from, %{repository: repository} = state) do
    {:reply, repository && repository.prov_graph, state}
  end

  def handle_call({:create, repo_spec, opts}, _from, %{store: store, status: :no_repo} = state) do
    case Initializer.create_repo(store, repo_spec, opts) do
      {:ok, repository} ->
        {:reply, {:ok, repository}, %{state | repository: repository, status: :ready}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:create, _, _}, _from, state) do
    {:reply, {:error, :repo_already_connected}, state}
  end

  def handle_call(operation, _from, %{status: :no_repo} = state) do
    {:reply, {:error, NotReadyError.exception(operation: operation)}, state}
  end
end
