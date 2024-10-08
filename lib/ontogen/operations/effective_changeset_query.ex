defmodule Ontogen.Operations.EffectiveChangesetQuery do
  use Ontogen.Operation.Query,
    params: [
      changeset: nil
    ]

  alias Ontogen.{SpeechAct, Commit, Service, NoEffectiveChanges}
  alias RDF.{Graph, Description}

  import Ontogen.QueryUtils

  api do
    def effective_changeset(args) do
      args
      |> EffectiveChangesetQuery.new()
      |> EffectiveChangesetQuery.__do_call__()
    end

    def effective_changeset!(args), do: bang!(&effective_changeset/1, [args])
  end

  def new(changeset_args) do
    with {:ok, changeset} <- SpeechAct.Changeset.new(changeset_args) do
      {:ok, %__MODULE__{changeset: changeset}}
    end
  end

  def new!(args \\ []), do: bang!(&new/1, [args])

  @impl true
  def call(
        %__MODULE__{
          changeset: %{add: add, remove: remove, update: update, replace: replace}
        },
        service
      ) do
    with {:ok, add_remove_change_graph} <-
           add_remove_query(add, remove, update, replace)
           |> Service.handle_sparql(service, :dataset),
         effective_add = effective_add(add, add_remove_change_graph),
         effective_update = effective_add(update, add_remove_change_graph),
         effective_replace = effective_add(replace, add_remove_change_graph),
         effective_remove = effective_remove(remove, add_remove_change_graph),
         {:ok, update_overwrites_graph} <- update_overwrites(service, update),
         {:ok, replace_overwrites_graph} <- replace_overwrites(service, replace),
         overwrite = overwrite_remove(update_overwrites_graph, replace_overwrites_graph) do
      if effective_add || effective_remove || effective_update || effective_replace ||
           overwrite do
        Commit.Changeset.new(
          add: effective_add,
          update: effective_update,
          replace: effective_replace,
          remove: effective_remove,
          overwrite: overwrite && Graph.delete(overwrite, effective_remove || [])
        )
      else
        {:ok, %NoEffectiveChanges{}}
      end
    end
  end

  defp update_overwrites(_, nil), do: {:ok, nil}

  defp update_overwrites(service, update) do
    with {:ok, update_overwrite_graph} <-
           update
           |> update_overwrites_query()
           |> Service.handle_sparql(service, :dataset) do
      {:ok, Graph.delete(update_overwrite_graph, update)}
    end
  end

  defp replace_overwrites(_, nil), do: {:ok, nil}

  defp replace_overwrites(service, replace) do
    with {:ok, replace_overwrite_graph} <-
           replace
           |> replace_overwrites_query()
           |> Service.handle_sparql(service, :dataset) do
      {:ok, Graph.delete(replace_overwrite_graph, replace)}
    end
  end

  defp effective_add(nil, _), do: nil

  defp effective_add(add, change_graph) do
    Enum.reduce(add, add, fn triple, effective_add ->
      if Graph.include?(change_graph, triple) do
        Graph.delete(effective_add, triple)
      else
        effective_add
      end
    end)
    |> non_empty_graph()
  end

  defp effective_remove(nil, _), do: nil

  defp effective_remove(remove, change_graph) do
    Enum.reduce(remove, remove, fn triple, effective_remove ->
      if Graph.include?(change_graph, triple) do
        effective_remove
      else
        Graph.delete(effective_remove, triple)
      end
    end)
    |> non_empty_graph()
  end

  defp overwrite_remove(update_overwrite, replace_overwrite) do
    do_overwrite_remove(
      non_empty_graph(update_overwrite),
      non_empty_graph(replace_overwrite)
    )
  end

  defp do_overwrite_remove(nil, nil), do: nil
  defp do_overwrite_remove(update_overwrite, nil), do: update_overwrite
  defp do_overwrite_remove(nil, replace_overwrite), do: replace_overwrite

  defp do_overwrite_remove(update_overwrite, replace_overwrite) do
    update_overwrite |> Graph.add(replace_overwrite) |> non_empty_graph()
  end

  defp non_empty_graph(nil), do: nil
  defp non_empty_graph(graph), do: unless(Graph.empty?(graph), do: graph)

  defp add_remove_query(add, remove, update, replace) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s ?p ?o ) {
        #{triples(add)}
        #{triples(remove)}
        #{triples(update)}
        #{triples(replace)}
      }
      ?s ?p ?o .
    }
    """
    |> Ontogen.Store.SPARQL.Operation.construct!()
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
    |> Ontogen.Store.SPARQL.Operation.construct!()
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
    |> Ontogen.Store.SPARQL.Operation.construct!()
  end

  defp subjects(replace) do
    replace
    |> Graph.subjects()
    |> Enum.map_join("\n", &"(#{to_term(&1)})")
  end
end
