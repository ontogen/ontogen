defmodule Ontogen.Commands.RepoInfo do
  alias Ontogen.{Repository, Store}
  alias RDF.Graph

  @preloading_depth 3

  def call(store, repo_id) do
    with {:ok, graph} <- Store.query(store, repo_id, query(repo_id)) do
      if Graph.describes?(graph, repo_id) do
        Repository.load(graph, repo_id, depth: @preloading_depth)
      else
        {:error, :repo_not_found}
      end
    end
  end

  defp query(repo_id) do
    """
    CONSTRUCT { ?s ?p ?o }
    FROM      <#{repo_id}>
    WHERE     { ?s ?p ?o }
    """
  end
end
