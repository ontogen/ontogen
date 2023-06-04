defmodule Ontogen.Commands.FetchDataset do
  alias Ontogen.Store

  def call(store, repository) do
    dataset_id = repository.dataset.__id__
    Store.query(store, dataset_id, query(dataset_id))
  end

  defp query(_dataset_id) do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end
end
