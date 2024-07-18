defmodule Ontogen.Operations.HistoryGraphQuery do
  use Ontogen.Query

  alias Ontogen.{Service, History}
  alias RDF.Graph

  import Ontogen.QueryUtils, only: [graph_query: 0]

  api do
    def history do
      # We're not performing the store access inside of the GenServer (by using __do_call__/1),
      # because we don't wont to block it for this potentially large read access.
      # Also, we don't want to pass the potentially large data structure between processes.
      HistoryGraphQuery.new!()
      |> HistoryGraphQuery.call(service())
    end

    def history!, do: bang!(&history/0, [])
  end

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  @impl true
  def call(%__MODULE__{}, service) do
    with {:ok, graph} <- Service.handle_sparql(graph_query(), service, :history) do
      {:ok, graph |> Graph.add_prefixes(History.prefixes())}
    end
  end
end
