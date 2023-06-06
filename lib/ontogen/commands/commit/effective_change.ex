defmodule Ontogen.Commands.Commit.EffectiveChange do
  alias Ontogen.{Commit, Expression, EffectiveExpression, Store, Repository}
  alias RDF.Graph

  def commit(store, repo, commit) do
    with {:ok, effective_insertion, effective_deletion} <-
           determine(store, repo, commit.insertion, commit.deletion) do
      Commit.effective(commit, effective_insertion, effective_deletion)
    end
  end

  def determine(store, repo, insertion, deletion) do
    inserts = Expression.graph(insertion)
    deletes = Expression.graph(deletion)

    with {:ok, change_graph} <-
           Store.construct(store, Repository.dataset_graph_id(repo), query(inserts, deletes)),
         {:ok, effective_insertion} <-
           effective_insertion(insertion, inserts, change_graph),
         {:ok, effective_deletion} <-
           effective_deletion(deletion, deletes, change_graph) do
      {:ok, effective_insertion, effective_deletion}
    end
  end

  defp effective_insertion(nil, _, _), do: {:ok, nil}

  defp effective_insertion(insertion, inserts, change_graph) do
    effective_inserts =
      inserts
      |> Enum.reduce(inserts, fn triple, inserts ->
        if Graph.include?(change_graph, triple) do
          Graph.delete(inserts, triple)
        else
          inserts
        end
      end)

    if Graph.empty?(effective_inserts) do
      {:ok, nil}
    else
      EffectiveExpression.new(insertion, effective_inserts)
    end
  end

  defp effective_deletion(nil, _, _), do: {:ok, nil}

  defp effective_deletion(deletion, deletes, change_graph) do
    effective_deletes =
      deletes
      |> Enum.reduce(deletes, fn triple, deletes ->
        if Graph.include?(change_graph, triple) do
          deletes
        else
          Graph.delete(deletes, triple)
        end
      end)

    if Graph.empty?(effective_deletes) do
      {:ok, nil}
    else
      EffectiveExpression.new(deletion, effective_deletes)
    end
  end

  defp query(inserts, deletes) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s ?p ?o ) {
        #{triples(inserts)}
        #{triples(deletes)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp triples(nil), do: ""

  defp triples(graph) do
    Enum.map_join(graph, "\n", fn {s, p, o} -> "(<#{s}> <#{p}> <#{o}>)" end)
  end
end
