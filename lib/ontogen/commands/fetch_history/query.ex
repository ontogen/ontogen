defmodule Ontogen.Commands.FetchHistory.Query do
  alias Ontogen.Repository
  alias Ontogen.NS.Og

  import Ontogen.QueryUtils

  def build(repository, subject, opts \\ [])

  def build(repository, {:dataset, _dataset_id}, opts) do
    do_build(repository, nil, opts)
  end

  def build(repository, {:resource, resource}, opts) do
    do_build(repository, resource, opts)
  end

  def build(repository, {:statement, statement}, opts) do
    do_build(repository, statement, opts)
  end

  defp do_build(repository, subject, opts) do
    with {:ok, from_commit} <- from_commit(repository, opts) do
      {:ok, query(subject, from_commit, to_commit(opts))}
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

  defp query(subject, from_commit, to_commit) do
    """
    PREFIX og: <#{Og.__base_iri__()}>
    PREFIX rtc: <#{RTC.__base_iri__()}>
    CONSTRUCT { #{commit_statements_construct_pattern()} }
    WHERE {
      <#{from_commit}> og:parentCommit* ?commit .
      #{filter_commits(to_commit)}
      #{commit_statements_query_pattern(subject)}
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
    ?update ?update_p ?update_o .
    ?replacement ?replacement_p ?replacement_o .
    ?committer ?committer_p ?committer_o .
    ?origin ?origin_p ?origin_o
    """
  end

  defp commit_statements_query_pattern(subject) do
    """
    ?commit ?commit_p ?commit_o .

      ?commit og:committer ?committer .
      ?committer ?committer_p ?committer_o .
      {
        {
          ?commit og:committedInsertion ?insertion .
          #{statement_filter("?insertion", subject)}
        }
        UNION
        {
          ?commit og:committedDeletion ?deletion .
          #{statement_filter("?deletion", subject)}
        }
        UNION
        {
          ?commit og:committedUpdate ?update .
          #{statement_filter("?update", subject)}
        }
        UNION
        {
          ?commit og:committedReplacement ?replacement .
          #{statement_filter("?replacement", subject)}
        }
      }

      OPTIONAL {
        ?commit og:committedInsertion ?insertion .
        ?insertion ?insertion_p ?insertion_o .
        OPTIONAL {
          ?insertion og:originExpression ?origin .
          ?origin ?origin_p ?origin_o .
        }
      }
      OPTIONAL {
        ?commit og:committedDeletion ?deletion .
        ?deletion ?deletion_p ?deletion_o .
        OPTIONAL {
          ?deletion og:originExpression ?origin .
          ?origin ?origin_p ?origin_o .
        }
      }
      OPTIONAL {
        ?commit og:committedUpdate ?update .
        ?update ?update_p ?update_o .
        OPTIONAL {
          ?update og:originExpression ?origin .
          ?origin ?origin_p ?origin_o .
        }
      }
      OPTIONAL {
        ?commit og:committedReplacement ?replacement .
        ?replacement ?replacement_p ?replacement_o .
        OPTIONAL {
          ?replacement og:originExpression ?origin .
          ?origin ?origin_p ?origin_o .
        }
      }
    """
  end

  defp statement_filter(_, nil), do: ""

  defp statement_filter(expression, {s, p, o}) do
    "#{expression} rtc:elements << #{to_term(s)} #{to_term(p)} #{to_term(o)} >> ."
  end

  defp statement_filter(expression, {s, p}) do
    "#{expression} rtc:elements << #{to_term(s)} #{to_term(p)} ?resource_o >> ."
  end

  defp statement_filter(expression, resource) do
    "#{expression} rtc:elements << #{to_term(resource)} ?resource_p ?resource_o >> ."
  end
end
