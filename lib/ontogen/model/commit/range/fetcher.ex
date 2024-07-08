defmodule Ontogen.Commit.Range.Fetcher do
  @moduledoc false

  alias Ontogen.{Commit, Service, Repository, InvalidCommitRangeError, EmptyRepositoryError}
  alias Ontogen.NS.Og
  alias RDF.{IRI, Graph, Description, PrefixMap}

  import RDF.Namespace.IRI

  def fetch(%Commit{__id__: id}, service), do: fetch(id, service)

  def fetch(:head, service) do
    head = Repository.head_id(service.repository)

    if head != Commit.root() do
      fetch(head, service)
    else
      {:error, EmptyRepositoryError.exception(repository: service.repository)}
    end
  end

  def fetch(%IRI{} = commit_id, service) do
    with {:ok, commit_graph} <-
           commit_id
           |> query()
           |> Service.handle_sparql(service, :prov) do
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
    |> Ontogen.Store.SPARQL.Operation.construct!()
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
