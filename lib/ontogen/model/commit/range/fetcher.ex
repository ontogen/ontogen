defmodule Ontogen.Commit.Range.Fetcher do
  @moduledoc false

  alias Ontogen.{Commit, Store, Repository, InvalidCommitRangeError, EmptyRepositoryError}
  alias Ontogen.NS.Og
  alias RDF.{IRI, Graph, Description, PrefixMap}

  import RDF.Namespace.IRI

  def fetch(%Commit{__id__: id}, store, repository), do: fetch(id, store, repository)

  def fetch(:head, store, repository) do
    head = Repository.head_id(repository)

    if head != Commit.root() do
      fetch(head, store, repository)
    else
      {:error, EmptyRepositoryError.exception(repository: repository)}
    end
  end

  def fetch(%IRI{} = commit_id, store, repository) do
    with {:ok, commit_graph} <-
           Store.construct(store, Repository.prov_graph_id(repository), query(commit_id),
             raw_mode: true
           ) do
      chain(commit_graph, commit_id)
    end
  end

  defp query(commit_id) do
    """
    #{[:og] |> Ontogen.NS.prefixes() |> PrefixMap.to_sparql()}
    CONSTRUCT {
      ?commit og:parentCommit ?parent .
    }
    WHERE {
      <#{commit_id}> og:parentCommit* ?commit .
      ?commit og:parentCommit ?parent .
    }
    """
  end

  defp chain(history_graph, current, acc \\ [])

  defp chain(_, nil, acc), do: {:ok, acc}
  defp chain(_, term_to_iri(Og.CommitRoot), acc), do: {:ok, Enum.reverse(acc)}

  defp chain(%Graph{descriptions: commits}, next, []) when not is_map_key(commits, next),
    do: {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}

  defp chain(commit_graph, next, acc) do
    chain(commit_graph, Description.first(commit_graph[next], Og.parentCommit()), [next | acc])
  end
end
