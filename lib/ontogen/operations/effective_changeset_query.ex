defmodule Ontogen.Operations.EffectiveChangesetQuery do
  use Ontogen.Query,
    params: [
      changeset: nil
    ]

  alias Ontogen.{SpeechAct, Commit, Store, Repository}
  alias RDF.{Graph, Description}

  import Ontogen.QueryUtils

  api do
    def effective_changeset(args) do
      args
      |> EffectiveChangesetQuery.new()
      |> EffectiveChangesetQuery.__do_call__()
    end

    def effective_changeset!(changeset) do
      case effective_changeset(changeset) do
        {:ok, changeset} -> changeset
        {:error, error} -> raise error
      end
    end

    defdelegate changes(changeset), to: __MODULE__, as: :effective_changeset
    defdelegate changes!(changeset), to: __MODULE__, as: :effective_changeset!
  end

  def new(changeset_args) do
    with {:ok, changeset} <- SpeechAct.Changeset.new(changeset_args) do
      {:ok, %__MODULE__{changeset: changeset}}
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, operation} -> operation
      {:error, error} -> raise error
    end
  end

  @impl true
  def call(
        %__MODULE__{
          changeset: %{insert: insert, delete: delete, update: update, replace: replace}
        },
        store,
        repo
      ) do
    dataset = Repository.dataset_graph_id(repo)

    with {:ok, insert_delete_change_graph} <-
           Store.construct(store, dataset, insert_delete_query(insert, delete, update, replace)),
         effective_insert = effective_insert(insert, insert_delete_change_graph),
         effective_update = effective_insert(update, insert_delete_change_graph),
         effective_replace = effective_insert(replace, insert_delete_change_graph),
         effective_delete = effective_delete(delete, insert_delete_change_graph),
         {:ok, update_overwrites_graph} <- update_overwrites(store, dataset, update),
         {:ok, replace_overwrites_graph} <- replace_overwrites(store, dataset, replace),
         overwrite = overwrite_delete(update_overwrites_graph, replace_overwrites_graph) do
      if effective_insert || effective_delete || effective_update || effective_replace ||
           overwrite do
        Commit.Changeset.new(
          insert: effective_insert,
          delete: effective_delete,
          update: effective_update,
          replace: effective_replace,
          overwrite: overwrite
        )
      else
        {:ok, :no_effective_changes}
      end
    end
  end

  defp update_overwrites(_, _, nil), do: {:ok, nil}

  defp update_overwrites(store, dataset, update) do
    with {:ok, update_overwrite_graph} <-
           Store.construct(store, dataset, update_overwrites_query(update)) do
      {:ok, Graph.delete(update_overwrite_graph, update)}
    end
  end

  defp replace_overwrites(_, _, nil), do: {:ok, nil}

  defp replace_overwrites(store, dataset, replace) do
    with {:ok, replace_overwrite_graph} <-
           Store.construct(store, dataset, replace_overwrites_query(replace)) do
      {:ok, Graph.delete(replace_overwrite_graph, replace)}
    end
  end

  defp effective_insert(nil, _), do: nil

  defp effective_insert(insert, change_graph) do
    Enum.reduce(insert, insert, fn triple, effective_insert ->
      if Graph.include?(change_graph, triple) do
        Graph.delete(effective_insert, triple)
      else
        effective_insert
      end
    end)
    |> non_empty_graph()
  end

  defp effective_delete(nil, _), do: nil

  defp effective_delete(delete, change_graph) do
    Enum.reduce(delete, delete, fn triple, effective_delete ->
      if Graph.include?(change_graph, triple) do
        effective_delete
      else
        Graph.delete(effective_delete, triple)
      end
    end)
    |> non_empty_graph()
  end

  defp overwrite_delete(update_overwrite, replace_overwrite) do
    do_overwrite_delete(
      non_empty_graph(update_overwrite),
      non_empty_graph(replace_overwrite)
    )
  end

  defp do_overwrite_delete(nil, nil), do: nil
  defp do_overwrite_delete(update_overwrite, nil), do: update_overwrite
  defp do_overwrite_delete(nil, replace_overwrite), do: replace_overwrite

  defp do_overwrite_delete(update_overwrite, replace_overwrite) do
    update_overwrite |> Graph.add(replace_overwrite) |> non_empty_graph()
  end

  defp non_empty_graph(nil), do: nil
  defp non_empty_graph(graph), do: unless(Graph.empty?(graph), do: graph)

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
