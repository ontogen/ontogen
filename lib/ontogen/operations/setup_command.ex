defmodule Ontogen.Operations.SetupCommand do
  use Ontogen.Command
  alias Ontogen.{Service, Store}
  alias Ontogen.Operations.{RepositoryQuery, BootCommand}
  alias Ontogen.Repository.SetupError

  api do
    def setup do
      SetupCommand.new()
      |> SetupCommand.__do_call__()
    end

    def setup!, do: bang!(&setup/0, [])
  end

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  def call(%Service{} = service) do
    new!() |> call(service)
  end

  @impl true
  def call(%__MODULE__{}, service) do
    with :ok <- ensure_repo_not_existing(service),
         {:ok, service} <- Service.set_head(service, :root),
         :ok <- init_repo_graph(service) do
      BootCommand.new!(log: false) |> BootCommand.call(service)
    end
  end

  defp ensure_repo_not_existing(service) do
    RepositoryQuery.new!(format: :boolean)
    |> RepositoryQuery.call(service)
    |> case do
      {:ok, true} -> {:error, SetupError.exception(service: service, reason: :already_setup)}
      {:ok, false} -> :ok
      {:error, _} = error -> error
    end
  end

  defp init_repo_graph(service) do
    service.repository
    |> Grax.to_rdf!()
    |> Store.SPARQL.Operation.insert_data!()
    |> Service.handle_sparql(service, :repo)
  end
end
