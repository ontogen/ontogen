defmodule Ontogen.Operations.DatasetQuery do
  use Ontogen.Query

  alias Ontogen.Service

  import Ontogen.QueryUtils, only: [graph_query: 0]

  api do
    def dataset do
      # We're not performing the store access inside of the GenServer (by using __do_call__/1),
      # because we don't wont to block it for this potentially large read access.
      # Also, we don't want to pass the potentially large data structure between processes.
      DatasetQuery.new!()
      |> DatasetQuery.call(service())
    end

    def dataset!, do: bang!(&dataset/0, [])
  end

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  @impl true
  def call(%__MODULE__{}, service) do
    Service.handle_sparql(graph_query(), service, :dataset)
  end
end
