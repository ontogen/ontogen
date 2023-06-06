defmodule Ontogen.Commands.FetchDataset do
  alias Ontogen.{Store, Repository}

  def call(store, repository) do
    dataset_id = Repository.dataset_graph_id(repository)
    Store.query(store, dataset_id, query(dataset_id))
  end

  defp query(_dataset_id) do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end
end
