defmodule Ontogen.Operations.ProvGraphQuery do
  use Ontogen.Query

  alias Ontogen.{Service, ProvGraph}
  alias RDF.Graph

  import Ontogen.QueryUtils, only: [graph_query: 0]

  api do
    def prov_graph do
      # We're not performing the store access inside of the GenServer (by using __do_call__/1),
      # because we don't wont to block it for this potentially large read access.
      # Also, we don't want to pass the potentially large data structure between processes.
      ProvGraphQuery.new!()
      |> ProvGraphQuery.call(service())
    end

    def prov_graph!, do: bang!(&prov_graph/0, [])
  end

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  @impl true
  def call(%__MODULE__{}, service) do
    with {:ok, graph} <- Service.handle_sparql(graph_query(), service, :prov) do
      {:ok, graph |> Graph.add_prefixes(ProvGraph.prefixes())}
    end
  end
end
