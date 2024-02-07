defmodule Ontogen.Operations.DatasetQuery do
  use Ontogen.Query

  alias Ontogen.{Store, Repository}

  import Ontogen.QueryUtils, only: [graph_query: 0]

  api do
    def dataset do
      # We're not performing the store access inside of the GenServer (by using __do_call__/1),
      # because we don't wont to block it for this potentially large read access.
      # Also, we don't want to pass the potentially large data structure between processes.
      DatasetQuery.new!()
      |> DatasetQuery.call(store(), repository())
    end
  end

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  @impl true
  def call(%__MODULE__{}, store, repository) do
    dataset_id = Repository.dataset_graph_id(repository)
    Store.query(store, dataset_id, graph_query())
  end
end
