defmodule Ontogen.Changeset.Validation do
  alias RDF.{Graph, Description}
  alias Ontogen.InvalidChangesetError

  @doc """
  Validates the given changeset structure.

  If valid, the given structure is returned unchanged in an `:ok` tuple.
  Otherwise, an `:error` tuple is returned.
  """
  def validate(
        %{add: add, update: update, replace: replace, remove: remove} = changeset,
        opts \\ []
      ) do
    with :ok <-
           check_statements_presence(
             Keyword.get(opts, :allow_empty, false),
             add,
             update,
             replace,
             remove,
             Map.get(changeset, :overwrite)
           ),
         :ok <- check_no_add_remove_overlap(add, update, replace, remove),
         :ok <- check_no_add_overlap(add, update, replace),
         :ok <- check_no_replace_overlap(add, update, replace),
         :ok <- check_no_update_overlap(add, update) do
      {:ok, changeset}
    end
  end

  defp check_statements_presence(false, nil, nil, nil, nil, nil),
    do: {:error, InvalidChangesetError.exception(reason: :empty)}

  defp check_statements_presence(_, _, _, _, _, _), do: :ok

  defp check_no_add_remove_overlap(add, update, replace, remove) do
    overlapping_statements =
      Enum.flat_map([add, update, replace], &overlapping_statements(&1, remove))

    if Enum.empty?(overlapping_statements) do
      :ok
    else
      {:error,
       InvalidChangesetError.exception(
         reason:
           "the following statements are in both add and remove: #{inspect(overlapping_statements)}"
       )}
    end
  end

  defp check_no_add_overlap(add, update, replace) do
    [
      {add, update},
      {add, replace},
      {update, replace}
    ]
    |> Enum.reduce_while(:ok, fn {graph1, graph2}, :ok ->
      overlapping_statements = overlapping_statements(graph1, graph2)

      if Enum.empty?(overlapping_statements) do
        {:cont, :ok}
      else
        {:halt,
         {:error,
          InvalidChangesetError.exception(
            reason:
              "the following statements are in multiple adds: #{inspect(overlapping_statements)}"
          )}}
      end
    end)
  end

  defp check_no_replace_overlap(_, _, nil), do: :ok

  defp check_no_replace_overlap(add, update, replace) do
    replace
    |> Graph.subjects()
    |> Enum.find_value(fn subject ->
      cond do
        update_description = update && update[subject] ->
          {:error,
           InvalidChangesetError.exception(
             reason:
               "the following update statements overlap with replace overwrites: #{inspect(Description.triples(update_description))}"
           )}

        add_description = add && add[subject] ->
          {:error,
           InvalidChangesetError.exception(
             reason:
               "the following add statements overlap with replace overwrites: #{inspect(Description.triples(add_description))}"
           )}

        true ->
          nil
      end
    end) || :ok
  end

  defp check_no_update_overlap(_, nil), do: :ok

  defp check_no_update_overlap(add, update) do
    update
    |> Graph.descriptions()
    |> Enum.find_value(fn description ->
      if add_description = add && add[description.subject] do
        description
        |> Description.predicates()
        |> Enum.find_value(fn predicate ->
          if add_description[predicate] do
            {:error,
             InvalidChangesetError.exception(
               reason:
                 "the following add statements overlap with update overwrites: #{inspect(add_description |> Description.take([predicate]) |> Description.triples())}"
             )}
          end
        end)
      end
    end) || :ok
  end

  defp overlapping_statements(nil, _), do: []
  defp overlapping_statements(_, nil), do: []

  defp overlapping_statements(graph, other_graphs) when is_list(other_graphs) do
    Enum.flat_map(other_graphs, &overlapping_statements(graph, &1))
  end

  defp overlapping_statements(graph1, graph2) do
    Enum.filter(graph2, &Graph.include?(graph1, &1))
  end
end
