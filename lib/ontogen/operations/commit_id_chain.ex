defmodule Ontogen.CommitIdChain do
  alias Ontogen.{Commit, Store, Repository, InvalidCommitRangeError}
  alias Ontogen.NS.Og
  alias RDF.{IRI, Graph, Description, PrefixMap}

  def fetch(%Commit.Range{} = range, store, repository) do
    with {:ok, chain} <- fetch(range.target, store, repository) do
      to_base(chain, range.base)
    end
  end

  def fetch(%Commit{__id__: id}, store, repository), do: fetch(id, store, repository)

  def fetch(:head, store, repository) do
    if head = Repository.head_id(repository) do
      fetch(head, store, repository)
    else
      {:error, :no_head}
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
      ?root_commit a og:RootCommit .
    }
    WHERE {
      {
        <#{commit_id}> og:parentCommit* ?commit .
        ?commit og:parentCommit ?parent .
      }
    UNION
      {
        BIND (<#{commit_id}> AS ?root_commit)
        ?root_commit og:committer ?committer .
        FILTER NOT EXISTS { ?root_commit og:parentCommit ?parent . }
      }
    }
    """
  end

  defp chain(history_graph, current, acc \\ [])

  defp chain(_, nil, acc), do: {:ok, acc}

  defp chain(%Graph{descriptions: commits}, next, []) when not is_map_key(commits, next),
    do: {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}

  defp chain(%Graph{descriptions: commits}, next, acc) when not is_map_key(commits, next),
    do: {:ok, Enum.reverse([next | acc])}

  defp chain(commit_graph, next, acc) do
    chain(commit_graph, Description.first(commit_graph[next], Og.parentCommit()), [next | acc])
  end

  def to_base(chain, nil), do: {:ok, chain}

  def to_base(chain, %RDF.IRI{} = base) do
    case Enum.split_while(chain, &(&1 != base)) do
      {_, []} -> {:error, InvalidCommitRangeError.exception(reason: :out_of_range)}
      {chain_to_base, _} -> {:ok, chain_to_base}
    end
  end

  def to_base!(chain, base) do
    case to_base(chain, base) do
      {:ok, result} -> result
      {:error, error} -> error
    end
  end
end
