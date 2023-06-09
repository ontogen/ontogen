defmodule Ontogen.Commands.Log do
  alias Ontogen.{Store, Repository, LogType}
  alias Ontogen.Commands.Log.Query

  def dataset(store, repository, opts \\ []) do
    call(store, repository, {:dataset, Repository.dataset_graph_id(repository)}, opts)
  end

  def call(store, repository, subject, opts \\ []) do
    with {:ok, query} <- Query.build(repository, subject, opts),
         {:ok, history_graph} <- Store.query(store, Repository.prov_graph_id(repository), query) do
      LogType.log(history_graph, subject, opts)
    end
  end
end
