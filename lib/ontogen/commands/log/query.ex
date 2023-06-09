defmodule Ontogen.Commands.Log.Query do
  alias Ontogen.Repository
  alias Ontogen.NS.Og

  def build(repository, {:dataset, _dataset_id}, opts \\ []) do
    {:ok, dataset_query(from_commit(repository, opts), to_commit(opts))}
  end

  defp from_commit(repository, opts) do
    Keyword.get(opts, :from_commit, Repository.head_id(repository))
  end

  defp to_commit(opts) do
    Keyword.get(opts, :to_commit)
  end

  defp dataset_query(from_commit, to_commit) do
    """
    PREFIX og: <#{Og.__base_iri__()}>
    CONSTRUCT { #{commit_statements_construct_pattern()} }
    WHERE {
      <#{from_commit}> og:parentCommit* ?commit .
      #{filter_commits(to_commit)}
      #{commit_statements_query_pattern()}
    }
    """
  end

  defp filter_commits(nil), do: ""

  defp filter_commits(to_commit) do
    "MINUS { <#{to_commit}> og:parentCommit* ?commit . }"
  end

  defp commit_statements_construct_pattern do
    """
    ?commit ?commit_p ?commit_o .
    ?insertion ?insertion_p ?insertion_o .
    ?deletion ?deletion_p ?deletion_o .
    ?committer ?committer_p ?committer_o .
    """
  end

  defp commit_statements_query_pattern do
    """
      ?commit ?commit_p ?commit_o .

      OPTIONAL {
        ?commit og:committedInsertion ?insertion .
        ?insertion ?insertion_p ?insertion_o .
      }
      OPTIONAL {
        ?commit og:committedDeletion ?deletion .
        ?deletion ?deletion_p ?deletion_o .
      }
      OPTIONAL {
        ?commit og:committer ?committer .
        ?committer ?committer_p ?committer_o .
      }
    """
  end
end
