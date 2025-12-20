defmodule Ontogen.Operations.GraphQuery do
  use Ontogen.Operation.Query, params: [graph: :primary]

  alias Ontogen.Service

  api do
    def graph(graph) do
      # We're not performing the store access inside of the GenServer (by using __do_call__/1),
      # because we don't wont to block it for this potentially large read access.
      # Also, we don't want to pass the potentially large data structure between processes.
      GraphQuery.new!(graph)
      |> GraphQuery.call(service())
    end

    def graph!(graph), do: bang!(&graph/1, [graph])

    def dataset do
      graph(:primary)
    end

    def dataset!, do: bang!(&dataset/0, [])
  end

  def new(graph), do: {:ok, new!(graph)}
  def new!(graph), do: %__MODULE__{graph: graph}

  @impl true
  def call(%__MODULE__{graph: graph}, service) do
    Gno.graph(graph, service: service)
  end

  def call(%Service{} = service, graph) do
    new!(graph) |> call(service)
  end
end
