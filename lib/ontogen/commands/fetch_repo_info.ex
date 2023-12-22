defmodule Ontogen.Commands.FetchRepoInfo do
  alias Ontogen.{Repository, Store}
  alias RDF.Graph

  @default_preloading_depth 2

  def call(store, repo_id, opts \\ []) do
    with {:ok, graph} <- Store.query(store, repo_id, query(repo_id)) do
      if Graph.describes?(graph, repo_id) do
        Repository.load(graph, repo_id,
          depth: Keyword.get(opts, :depth, @default_preloading_depth)
        )
      else
        {:error, :repo_not_found}
      end
    end
  end

  defp query(_repo_id) do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end
end
