defmodule Ontogen do
  use GenServer

  alias Ontogen.{Service, Repository, ConfigError}
  alias Ontogen.Operation.{Query, Command}

  import Ontogen.Operation, only: [include_api: 1]

  include_api Ontogen.Operations.BootCommand
  include_api Ontogen.Operations.SetupCommand

  include_api Ontogen.Operations.CleanCommand
  include_api Ontogen.Operations.CommitCommand
  include_api Ontogen.Operations.RevertCommand
  include_api Ontogen.Operations.EffectiveChangesetQuery
  include_api Ontogen.Operations.ChangesetQuery
  include_api Ontogen.Operations.RevisionQuery
  include_api Ontogen.Operations.HistoryQuery
  include_api Ontogen.Operations.DatasetQuery
  include_api Ontogen.Operations.RepositoryQuery

  @allow_configless_mode Application.compile_env(:ontogen, :allow_configless_mode, false)

  @env Application.compile_env(:ontogen, :env, Mix.env())
  def env, do: @env

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)

  def service, do: GenServer.call(__MODULE__, :service)

  def store, do: GenServer.call(__MODULE__, :store)

  def dataset_info, do: GenServer.call(__MODULE__, :dataset_info)

  def history_info, do: GenServer.call(__MODULE__, :history_info)

  def head, do: GenServer.call(__MODULE__, :head)

  def reload, do: GenServer.call(__MODULE__, :reload)

  ############################################################################

  # Server (callbacks)

  @impl true
  def init(opts) do
    {:ok, nil, {:continue, {:boot, opts}}}
  end

  @impl true
  def handle_continue({:boot, opts}, _) do
    case BootCommand.call(opts) do
      {:ok, service} ->
        {:noreply, service}

      {:error, error} ->
        if @allow_configless_mode do
          {:noreply, {:error, error}}
        else
          {:stop, error}
        end
    end
  end

  @impl true
  def handle_call(%BootCommand{} = operation, from, {:error, _}),
    do: handle_call(operation, from, nil)

  def handle_call(%BootCommand{} = operation, from, nil),
    do: handle_call(operation, from, Ontogen.Config.service!())

  def handle_call(%BootCommand{} = operation, _from, service) do
    case BootCommand.call(operation, service) do
      {:ok, service} -> {:reply, {:ok, service}, service}
      {:error, _} = error -> {:reply, error, service}
    end
  end

  def handle_call(:status, _from, {:error, error}),
    do: {:reply, ConfigError.exception(reason: error), {:error, error}}

  def handle_call(:status, _from, nil), do: {:reply, :unconfigured, nil}
  def handle_call(:status, _from, service), do: {:reply, service.status, service}

  def handle_call(_operation, _from, nil) do
    {:reply, {:error, ConfigError.exception(reason: :missing)}, nil}
  end

  def handle_call(_operation, _from, {:error, error}) do
    {:reply, {:error, ConfigError.exception(reason: error)}, {:error, error}}
  end

  def handle_call(:service, _from, service), do: {:reply, service, service}
  def handle_call(:store, _from, service), do: {:reply, service.store, service}

  def handle_call(:dataset_info, _from, service),
    do: {:reply, service.repository.dataset, service}

  def handle_call(:history_info, _from, service),
    do: {:reply, service.repository.history, service}

  def handle_call(%SetupCommand{} = operation, _from, %Service{status: :not_setup} = service) do
    case SetupCommand.call(operation, service) do
      {:ok, service} -> {:reply, {:ok, service}, service}
      {:error, _} = error -> {:reply, error, service}
    end
  end

  def handle_call(%SetupCommand{}, _from, service) do
    {:reply, {:error, Repository.SetupError.exception(service: service, reason: :already_setup)},
     service}
  end

  def handle_call(operation, _from, %{status: :not_setup} = service) do
    {:reply, {:error, Repository.NotSetupError.exception(service: service, operation: operation)},
     service}
  end

  def handle_call(:head, _from, service) do
    {:reply, service.repository.head, service}
  end

  def handle_call(%operation{type: Query} = query, _from, service) do
    case apply(operation, :call, [query, service]) do
      {:ok, result} -> {:reply, {:ok, result}, service}
      {:error, _} = error -> {:reply, error, service}
    end
  end

  def handle_call(%operation{type: Command} = command, _from, service) do
    case apply(operation, :call, [command, service]) do
      {:ok, %Service{} = service} -> {:reply, :ok, service}
      {:ok, %Service{} = service, result} -> {:reply, {:ok, result}, service}
      {:error, _} = error -> {:reply, error, service}
    end
  end
end
