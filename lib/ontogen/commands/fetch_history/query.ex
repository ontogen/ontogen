defmodule Ontogen.Commands.FetchHistory.Query do
  alias Ontogen.Repository
  alias Ontogen.NS.Og

  import Ontogen.QueryUtils

  def build(repository, subject, opts \\ [])

  def build(repository, {:dataset, _dataset_id}, opts) do
    with {:ok, from_commit} <- from_commit(repository, opts) do
      {:ok, query(nil, from_commit, to_commit(opts))}
    end
  end

  def build(repository, {:resource, resource}, opts) do
    with {:ok, from_commit} <- from_commit(repository, opts) do
      {:ok, query(resource, from_commit, to_commit(opts))}
    end
  end

  defp from_commit(repository, opts) do
    if commit = Keyword.get(opts, :from_commit, Repository.head_id(repository)) do
      {:ok, commit}
    else
      {:error, :no_head}
    end
  end

  defp to_commit(opts) do
    Keyword.get(opts, :to_commit)
  end

  defp query(resource, from_commit, to_commit) do
    """
    PREFIX og: <#{Og.__base_iri__()}>
    PREFIX rtc: <#{RTC.__base_iri__()}>
    CONSTRUCT { #{commit_statements_construct_pattern()} }
    WHERE {
      <#{from_commit}> og:parentCommit* ?commit .
      #{filter_commits(to_commit)}
      #{commit_statements_query_pattern(resource)}
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

  defp commit_statements_query_pattern(resource) do
    """
    ?commit ?commit_p ?commit_o .

      ?commit og:committer ?committer .
      ?committer ?committer_p ?committer_o .
      {
        {
          ?commit og:committedInsertion ?insertion .
          #{resource_filter("?insertion", resource)}
        }
        UNION
        {
          ?commit og:committedDeletion ?deletion .
          #{resource_filter("?deletion", resource)}
        }
      }

      OPTIONAL {
        ?commit og:committedInsertion ?insertion .
        ?insertion ?insertion_p ?insertion_o .
      }
      OPTIONAL {
        ?commit og:committedDeletion ?deletion .
        ?deletion ?deletion_p ?deletion_o .
      }
    """
  end

  defp resource_filter(_, nil), do: ""

  defp resource_filter(expression, resource) do
    "#{expression} rtc:elements << #{to_term(resource)} ?resource_p ?resource_o >> ."
  end
end
