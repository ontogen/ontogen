defmodule Ontogen.Changeset.Validation do
  alias RDF.{Graph, Description}
  alias Ontogen.InvalidChangesetError

  @doc """
  Validates the given changeset structure.

  If valid, the given structure is returned unchanged in an `:ok` tuple.
  Otherwise, an `:error` tuple is returned.
  """
  def validate(%{insert: insert, delete: delete, update: update, replace: replace} = changeset) do
    with :ok <- check_statements_presence(insert, delete, update, replace),
         :ok <- check_no_insert_delete_overlap(insert, delete, update, replace),
         :ok <- check_no_inserts_overlap(insert, update, replace),
         :ok <- check_no_replace_overlap(insert, update, replace),
         :ok <- check_no_update_overlap(insert, update) do
      {:ok, changeset}
    end
  end

  defp check_statements_presence(nil, nil, nil, nil),
    do: {:error, InvalidChangesetError.exception(reason: :empty)}

  defp check_statements_presence(_, _, _, _), do: :ok

  defp check_no_insert_delete_overlap(insert, delete, update, replace) do
    overlapping_statements =
      Enum.flat_map([insert, update, replace], &overlapping_statements(&1, delete))

    if Enum.empty?(overlapping_statements) do
      :ok
    else
      {:error,
       InvalidChangesetError.exception(
         reason:
           "the following statements are in both insert and delete: #{inspect(overlapping_statements)}"
       )}
    end
  end

  defp check_no_inserts_overlap(insert, update, replace) do
    [
      {insert, update},
      {insert, replace},
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
              "the following statements are in multiple inserts: #{inspect(overlapping_statements)}"
          )}}
      end
    end)
  end

  defp check_no_replace_overlap(_, _, nil), do: :ok

  defp check_no_replace_overlap(insert, update, replace) do
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

        insert_description = insert && insert[subject] ->
          {:error,
           InvalidChangesetError.exception(
             reason:
               "the following insert statements overlap with replace overwrites: #{inspect(Description.triples(insert_description))}"
           )}

        true ->
          nil
      end
    end) || :ok
  end

  defp check_no_update_overlap(_, nil), do: :ok

  defp check_no_update_overlap(insert, update) do
    update
    |> Graph.descriptions()
    |> Enum.find_value(fn description ->
      if insert_description = insert && insert[description.subject] do
        description
        |> Description.predicates()
        |> Enum.find_value(fn predicate ->
          if insert_description[predicate] do
            {:error,
             InvalidChangesetError.exception(
               reason:
                 "the following insert statements overlap with update overwrites: #{inspect(insert_description |> Description.take([predicate]) |> Description.triples())}"
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
