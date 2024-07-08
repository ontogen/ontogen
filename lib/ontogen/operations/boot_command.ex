defmodule Ontogen.Operations.BootCommand do
  use Ontogen.Command, params: [:service_config, :log]
  require Logger

  alias Ontogen.{Service, Repository}
  alias Ontogen.Operations.RepositoryQuery
  alias Ontogen.Repository.NotSetupError

  api do
    def boot(opts \\ []) do
      BootCommand.new(opts)
      |> BootCommand.__do_call__()
    end

    def boot!(opts \\ []), do: bang!(&boot/1, [opts])
  end

  def new(opts \\ []) do
    {log?, service_config} = Keyword.pop(opts, :log, true)

    {:ok, %__MODULE__{service_config: service_config, log: log?}}
  end

  def new!(opts \\ []), do: bang!(&new/1, [opts])

  def call(opts \\ [])

  def call(%__MODULE__{service_config: service_config} = command) do
    if command.log, do: Logger.info("Loading service config")

    with {:ok, service} <- Ontogen.Config.service(:this, service_config) do
      call(command, service)
    end
  end

  def call(opts) do
    opts
    |> new!()
    |> call()
  end

  @impl true
  def call(%__MODULE__{} = command, service) do
    if command.log, do: Logger.info("Booting service #{service.__id__}")

    with {:ok, stored_repo} <- RepositoryQuery.call(service),
         {:ok, synced_repo} <- merge_sync(service, stored_repo) do
      {:ok, Service.set_status(synced_repo, :ready)}
    else
      {:error, %NotSetupError{service: service}} ->
        {:ok, Service.set_status(service, :not_setup)}

      error ->
        error
    end
  end

  defp merge_sync(%Service{} = service, %Repository{} = stored_repo) do
    with {:ok, repository} <- merge_sync(service.repository, stored_repo) do
      {:ok, %Service{service | repository: repository}}
    end
  end

  defp merge_sync(%Repository{} = _configured, %Repository{} = stored) do
    {:ok, stored}
  end
end
