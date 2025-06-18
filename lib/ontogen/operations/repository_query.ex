defmodule Ontogen.Operations.RepositoryQuery do
  use Ontogen.Operation.Query, params: [format: nil, stored: nil]

  alias Ontogen.Service

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
      format when format in ~w[native raw]a -> {:ok, format}
      invalid -> {:error, "invalid RepositoryQuery format: #{inspect(invalid)}"}
    end
  end

  def new!(opts \\ []), do: bang!(&new/1, [opts])

  def call(%Service{} = service) do
    new!(stored: true) |> call(service)
  end

  @impl true
  def call(operation, service)

  def call(%__MODULE__{format: :native, stored: false}, service) do
    {:ok, service.repository}
  end

  def call(%__MODULE__{format: :raw, stored: false}, service) do
    Grax.to_rdf(service.repository)
  end

  def call(%__MODULE__{format: :raw, stored: true}, service) do
    Gno.Service.fetch_repository_graph(service)
  end

  def call(%__MODULE__{format: :native, stored: true}, service) do
    Gno.Service.fetch_repository(service, depth: @default_preloading_depth)
  end
end
