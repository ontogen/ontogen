defmodule Ontogen.Operations.RepositoryQuery do
  use Ontogen.Query, params: [format: nil, stored: nil]

  alias Ontogen.{Service, Repository}
  alias Ontogen.Store.SPARQL.Operation
  alias Ontogen.Repository.NotSetupError
  alias Ontogen.NS.Og
  alias RDF.PrefixMap

  import Ontogen.QueryUtils, only: [graph_query: 0]

  @default_preloading_depth 2

  api do
    def repository(opts \\ []) do
      opts
      |> RepositoryQuery.new()
      |> RepositoryQuery.__do_call__()
    end

    def repository!(opts \\ []), do: bang!(&repository/1, [opts])
  end

  def new(opts \\ []) do
    with {:ok, format} <- format(opts) do
      {:ok, %__MODULE__{format: format, stored: Keyword.get(opts, :stored, false)}}
    end
  end

  defp format(opts) do
    case Keyword.get(opts, :format, :native) do
      format when format in ~w[native raw boolean]a -> {:ok, format}
      invalid -> {:error, "invalid RepositoryQuery format: #{inspect(invalid)}"}
    end
  end

  def new!(opts \\ []), do: bang!(&new/1, [opts])

  def call(%Service{} = service) do
    new!(stored: true) |> call(service)
  end

  @impl true
  def call(operation, service)

  def call(%__MODULE__{format: :boolean}, service) do
    case repository_exists_query(service, service.repository) do
      {:ok, %SPARQL.Query.Result{results: result}} -> {:ok, result}
      {:error, _} = error -> error
    end
  end

  def call(%__MODULE__{format: :native, stored: false}, service) do
    {:ok, service.repository}
  end

  def call(%__MODULE__{format: :raw, stored: false}, service) do
    Grax.to_rdf(service.repository)
  end

  def call(%__MODULE__{format: :raw, stored: true}, service) do
    repository_graph(service)
  end

  def call(%__MODULE__{format: :native, stored: true}, service) do
    with {:ok, graph} <- repository_graph(service) do
      Repository.load(graph, service.repository.__id__, depth: @default_preloading_depth)
    end
  end

  defp repository_exists_query(service, repository) do
    """
    #{[:og] |> Ontogen.NS.prefixes() |> PrefixMap.to_sparql()}
    ASK WHERE { <#{repository.__id__}> a og:Repository . }
    """
    |> Operation.ask!()
    |> Service.handle_sparql(service, :repo)
  end

  defp repository_graph(service) do
    with {:ok, graph} <- Service.handle_sparql(graph_query(), service, :repo) do
      if repository_exists?(graph, service.repository) do
        {:ok, graph}
      else
        {:error, NotSetupError.exception(service: service)}
      end
    end
  end

  defp repository_exists?(graph, repository) do
    RDF.Graph.include?(graph, {repository.__id__, RDF.type(), Og.Repository})
  end
end
