defmodule Ontogen.Commands.FetchEffectiveChangeset do
  alias Ontogen.{Changeset, Expression, EffectiveExpression, Store, Repository}
  alias RDF.{Graph, Description}

  import Ontogen.QueryUtils

  def call(store, repo, %Changeset{
        insertion: insertion_expr,
        deletion: deletion_expr,
        update: update_expr,
        replacement: replacement_expr
      }) do
    insert = Expression.graph(insertion_expr)
    delete = Expression.graph(deletion_expr)
    update = Expression.graph(update_expr)
    replace = Expression.graph(replacement_expr)

    dataset = Repository.dataset_graph_id(repo)

    with {:ok, insert_delete_change_graph} <-
           Store.construct(store, dataset, insert_delete_query(insert, delete, update, replace)),
         {:ok, effective_insertion} <-
           effective_insertion(insertion_expr, insert, insert_delete_change_graph),
         {:ok, effective_update} <-
           effective_insertion(update_expr, update, insert_delete_change_graph),
         {:ok, effective_replacement} <-
           effective_insertion(replacement_expr, replace, insert_delete_change_graph),
         {:ok, effective_deletion} <-
           effective_deletion(deletion_expr, delete, insert_delete_change_graph),
         {:ok, update_overwrites} <-
           update_overwrites(store, dataset, update_expr, update),
         {:ok, replace_overwrites} <-
           replace_overwrites(store, dataset, replacement_expr, replace) do
      if effective_insertion || effective_deletion || effective_update || effective_replacement do
        Changeset.new(
          insert: effective_insertion,
          delete: effective_deletion,
          delete: update_overwrites,
          delete: replace_overwrites,
          update: effective_update,
          replace: effective_replacement
        )
      else
        {:ok, :no_effective_changes}
      end
    end
  end

  def call(store, repo, changeset_args) do
    with {:ok, changeset} <- Changeset.new(changeset_args) do
      call(store, repo, changeset)
    end
  end

  defp update_overwrites(_, _, _, nil), do: {:ok, nil}

  defp update_overwrites(store, dataset, update_expr, update) do
    with {:ok, update_overwrite_graph} <-
           Store.construct(store, dataset, update_overwrites_query(update)) do
      overwrite_deletion(update_expr, Graph.delete(update_overwrite_graph, update))
    end
  end

  defp replace_overwrites(_, _, _, nil), do: {:ok, nil}

  defp replace_overwrites(store, dataset, replacement_expr, replace) do
    with {:ok, replace_overwrite_graph} <-
           Store.construct(store, dataset, replace_overwrites_query(replace)) do
      overwrite_deletion(replacement_expr, Graph.delete(replace_overwrite_graph, replace))
    end
  end

  defp effective_insertion(nil, _, _), do: {:ok, nil}

  defp effective_insertion(insertion, insert, change_graph) do
    effective_insert =
      Enum.reduce(insert, insert, fn triple, effective_insert ->
        if Graph.include?(change_graph, triple) do
          Graph.delete(effective_insert, triple)
        else
          effective_insert
        end
      end)

    if Graph.empty?(effective_insert) do
      {:ok, nil}
    else
      EffectiveExpression.new(insertion, effective_insert)
    end
  end

  defp effective_deletion(nil, _, _), do: {:ok, nil}

  defp effective_deletion(deletion, delete, change_graph) do
    effective_delete =
      Enum.reduce(delete, delete, fn triple, effective_delete ->
        if Graph.include?(change_graph, triple) do
          effective_delete
        else
          Graph.delete(effective_delete, triple)
        end
      end)

    if Graph.empty?(effective_delete) do
      {:ok, nil}
    else
      EffectiveExpression.new(deletion, effective_delete)
    end
  end

  defp overwrite_deletion(origin, overwrite_graph) do
    if Graph.empty?(overwrite_graph) do
      {:ok, nil}
    else
      EffectiveExpression.new(origin, overwrite_graph, only_subset: false)
    end
  end

  defp insert_delete_query(insert, delete, update, replace) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s ?p ?o ) {
        #{triples(insert)}
        #{triples(delete)}
        #{triples(update)}
        #{triples(replace)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp triples(nil), do: ""

  defp triples(graph) do
    Enum.map_join(graph, "\n", fn {s, p, o} ->
      "(#{to_term(s)} #{to_term(p)} #{to_term(o)})"
    end)
  end

  defp update_overwrites_query(nil), do: ""

  defp update_overwrites_query(update) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s ?p) {
        #{subject_predicate_pairs(update)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp subject_predicate_pairs(update) do
    update
    |> Graph.descriptions()
    |> Enum.flat_map(fn description ->
      description
      |> Description.predicates()
      |> Enum.map(&{description.subject, &1})
    end)
    |> Enum.map_join("\n", fn {s, p} -> "(#{to_term(s)} #{to_term(p)})" end)
  end

  defp replace_overwrites_query(nil), do: ""

  defp replace_overwrites_query(replace) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s) {
        #{subjects(replace)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp subjects(replace) do
    replace
    |> Graph.subjects()
    |> Enum.map_join("\n", &"(#{to_term(&1)})")
  end
end
