defmodule Ontogen.Operations.HistoryQuery.Query do
  @moduledoc false

  alias Ontogen.NS.Og

  import Ontogen.QueryUtils

  def build(operation) do
    {:ok, query(operation.subject, operation.range)}
  end

  defp query(subject, range) do
    """
    PREFIX og: <#{Og.__base_iri__()}>
    PREFIX rtc: <#{RTC.__base_iri__()}>
    CONSTRUCT { #{commit_statements_construct_pattern()} }
    WHERE {
      <#{range.target}> og:parentCommit* ?commit .
      #{filter_commits(range.base)}
      #{commit_statements_query_pattern(subject)}
    }
    """
  end

  defp filter_commits(nil), do: ""

  defp filter_commits(base_commit) do
    "MINUS { <#{base_commit}> og:parentCommit* ?commit . }"
  end

  defp commit_statements_construct_pattern do
    """
    ?commit ?commit_p ?commit_o .
    ?committed_add ?committed_add_p ?committed_add_o .
    ?committed_remove ?committed_remove_p ?committed_remove_o .
    ?committed_update ?committed_update_p ?committed_update_o .
    ?committed_replace ?committed_replace_p ?committed_replace_o .
    ?committed_overwrite ?committed_overwrite_p ?committed_overwrite_o .
    ?committer ?committer_p ?committer_o .
    ?speech_act ?speech_act_p ?speech_act_o .
    ?speaker ?speaker_p ?speaker_o .
    ?add ?add_p ?add_o .
    ?remove ?remove_p ?remove_o .
    ?update ?update_p ?update_o .
    ?replace ?replace_p ?replace_o .
    """
  end

  defp commit_statements_query_pattern(subject) do
    """
    ?commit
        ?commit_p ?commit_o ;
        og:committer ?committer ;
        og:speechAct ?speech_act .

      ?committer ?committer_p ?committer_o .

      {
        {
          ?commit og:committedAdd ?committed_add .
          #{statement_filter("?committed_add", subject)}
        }
        UNION
        {
          ?commit og:committedRemove ?committed_remove .
          #{statement_filter("?committed_remove", subject)}
        }
        UNION
        {
          ?commit og:committedUpdate ?committed_update .
          #{statement_filter("?committed_update", subject)}
        }
        UNION
        {
          ?commit og:committedReplace ?committed_replace .
          #{statement_filter("?committed_replace", subject)}
        }
        UNION
        {
          ?commit og:committedOverwrite ?committed_overwrite .
          #{statement_filter("?committed_overwrite", subject)}
        }
      }

      OPTIONAL {
        ?commit og:committedAdd ?committed_add .
        ?committed_add ?committed_add_p ?committed_add_o .
      }
      OPTIONAL {
        ?commit og:committedRemove ?committed_remove .
        ?committed_remove ?committed_remove_p ?committed_remove_o .
      }
      OPTIONAL {
        ?commit og:committedUpdate ?committed_update .
        ?committed_update ?committed_update_p ?committed_update_o .
      }
      OPTIONAL {
        ?commit og:committedReplace ?committed_replace .
        ?committed_replace ?committed_replace_p ?committed_replace_o .
      }
      OPTIONAL {
        ?commit og:committedOverwrite ?committed_overwrite .
        ?committed_overwrite ?committed_overwrite_p ?committed_overwrite_o .
      }

      ?speech_act
        ?speech_act_p ?speech_act_o ;
        og:speaker ?speaker .

      ?speaker ?speaker_p ?speaker_o .

      OPTIONAL {
        ?speech_act og:add ?add .
        ?add ?add_p ?add_o .
      }
      OPTIONAL {
        ?speech_act og:remove ?remove .
        ?remove ?remove_p ?remove_o .
      }
      OPTIONAL {
        ?speech_act og:update ?update .
        ?update ?update_p ?update_o .
      }
      OPTIONAL {
        ?speech_act og:replace ?replace .
        ?replace ?replace_p ?replace_o .
      }
    """
  end

  defp statement_filter(_, nil), do: ""

  defp statement_filter(proposition, {s, p, o}) do
    "#{proposition} rtc:elements << #{to_term(s)} #{to_term(p)} #{to_term(o)} >> ."
  end

  defp statement_filter(proposition, {s, p}) do
    "#{proposition} rtc:elements << #{to_term(s)} #{to_term(p)} ?resource_o >> ."
  end

  defp statement_filter(proposition, resource) do
    "#{proposition} rtc:elements << #{to_term(resource)} ?resource_p ?resource_o >> ."
  end
end
