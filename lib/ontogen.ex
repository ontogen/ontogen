defmodule Ontogen do
  use Magma
  use GenServer

  require Logger

  alias Ontogen.{Query, Command, Repository, Store, Config}
  alias Ontogen.Config.Repository.IdFile

  import Ontogen.Operation, only: [include_api: 1]

  include_api Ontogen.Operations.CreateRepositoryCommand
  include_api Ontogen.Operations.ClearRepositoryCommand
  include_api Ontogen.Operations.CommitCommand
  include_api Ontogen.Operations.RevertCommand
  include_api Ontogen.Operations.EffectiveChangesetQuery
  include_api Ontogen.Operations.ChangesetQuery
  include_api Ontogen.Operations.RevisionQuery
  include_api Ontogen.Operations.HistoryQuery
  include_api Ontogen.Operations.DatasetQuery
  include_api Ontogen.Operations.ProvGraphQuery

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

  def head do
    GenServer.call(__MODULE__, :head)
  end

  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  ############################################################################

  # Server (callbacks)

  @impl true
  def init(opts) do
    store = store(opts)

    with {:ok, repo_id} <- repo_id(opts),
         {:ok, repository} <- Store.repository(store, repo_id) do
      Logger.info("Connected to repo #{repository.__id__}")
      {:ok, %{repository: repository, store: store, status: :ready}}
    else
      {:error, :repo_not_defined} ->
        Logger.warning("Repo not specified, you'll have to create one first.")
        {:ok, %{repository: nil, store: store, status: :no_repo}}

      {:error, :repo_not_found} ->
        Logger.warning("Repo not found, you'll have to create one first.")
        {:ok, %{repository: nil, store: store, status: :no_repo}}

      {:error, error} ->
        {:stop, error}
    end
  end

  defp repo_id(opts) do
    cond do
      repo_id = Keyword.get(opts, :repo) -> {:ok, RDF.iri(repo_id)}
      repo_id = IdFile.read() -> {:ok, RDF.iri(repo_id)}
      repo_id = Application.get_env(:ontogen, :repo) -> {:ok, RDF.iri(repo_id)}
      true -> {:error, :repo_not_defined}
    end
  end

  defp store(opts), do: Keyword.get(opts, :store, Config.store())

  @impl true
  def handle_call(:status, _from, %{status: status} = state) do
    {:reply, status, state}
  end

  def handle_call(:store, _from, %{store: store} = state) do
    {:reply, store, state}
  end

  def handle_call(
        %CreateRepositoryCommand{} = operation,
        _from,
        %{store: store, status: :no_repo} = state
      ) do
    case CreateRepositoryCommand.call(operation, store) do
      {:ok, repo} -> {:reply, {:ok, repo}, %{state | repository: repo, status: :ready}}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call(%CreateRepositoryCommand{}, _from, state) do
    {:reply, {:error, :repo_already_connected}, state}
  end

  def handle_call(operation, _from, %{status: :no_repo} = state) do
    {:reply, {:error, Repository.NotReadyError.exception(operation: operation)}, state}
  end

  def handle_call(:reload, _from, %{store: store, repository: repository} = state) do
    case Store.repository(store, repository.__id__) do
      {:ok, repo} -> {:reply, {:ok, repo}, %{state | repository: repo}}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call(:repository, _from, %{repository: repo} = state) do
    {:reply, repo, state}
  end

  def handle_call(:dataset_info, _from, %{repository: repo} = state) do
    {:reply, repo.dataset, state}
  end

  def handle_call(:prov_graph_info, _from, %{repository: repo} = state) do
    {:reply, repo.prov_graph, state}
  end

  def handle_call(:head, _from, %{repository: repo} = state) do
    {:reply, repo.head, state}
  end

  def handle_call(
        %operation{type: Query} = query,
        _from,
        %{repository: repo, store: store} = state
      ) do
    case apply(operation, :call, [query, store, repo]) do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call(
        %operation{type: Command} = command,
        _from,
        %{repository: repo, store: store} = state
      ) do
    case apply(operation, :call, [command, store, repo]) do
      {:ok, %Repository{} = repo} -> {:reply, :ok, %{state | repository: repo}}
      {:ok, %Repository{} = repo, result} -> {:reply, {:ok, result}, %{state | repository: repo}}
      {:error, _} = error -> {:reply, error, state}
    end
  end
end
