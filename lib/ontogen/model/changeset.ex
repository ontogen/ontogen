defmodule Ontogen.Changeset do
  defstruct [:insertion, :deletion, :update, :replacement, :overwrite]

  alias Ontogen.{Proposition, Utterance, InvalidChangesetError}
  alias RDF.{Graph, Description}

  @keys [:insert, :delete, :update, :replace, :overwrite]
  def keys, do: @keys

  def new(%__MODULE__{} = changeset) do
    validate(changeset)
  end

  def new(%Utterance{} = utterance) do
    __MODULE__
    |> struct(Map.from_struct(utterance))
    |> validate()
  end

  def new(args) do
    case extract(args) do
      {:ok, changeset, _} -> {:ok, changeset}
      error -> error
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, changeset} -> changeset
      {:error, error} -> raise error
    end
  end

  def extract(args) do
    {insert, args} = extract_change(args, :insert)
    {delete, args} = extract_change(args, :delete)
    {update, args} = extract_change(args, :update)
    {replace, args} = extract_change(args, :replace)
    {overwrite, args} = extract_change(args, :overwrite)

    case Keyword.pop(args, :changeset) do
      {nil, args} ->
        with :ok <- do_validate(insert, delete, update, replace, overwrite),
             {:ok, insertion} <- build_proposition(insert),
             {:ok, deletion} <- build_proposition(delete),
             {:ok, update} <- build_proposition(update),
             {:ok, replacement} <- build_proposition(replace),
             {:ok, overwrite} <- build_proposition(overwrite) do
          {:ok,
           %__MODULE__{
             insertion: insertion,
             deletion: deletion,
             update: update,
             replacement: replacement,
             overwrite: overwrite
           }, args}
        end

      {_changeset, _args}
      when not (is_nil(insert) and is_nil(delete) and is_nil(update) and is_nil(replace) and
                    is_nil(overwrite)) ->
        {:error,
         InvalidChangesetError.exception(
           reason: "a changeset can not be used with additional changes"
         )}

      {changeset, args} ->
        with {:ok, changeset} <- new(changeset) do
          {:ok, changeset, args}
        end
    end
  end

  defp build_proposition(nil), do: {:ok, nil}
  defp build_proposition(%Proposition{} = proposition), do: {:ok, proposition}
  defp build_proposition(graph), do: Proposition.new(graph)

  defp extract_change(args, key) do
    {values, args} = Keyword.pop_values(args, key)

    case Enum.reject(values, &is_nil/1) do
      [] -> {nil, args}
      [value] -> {to_graph(value), args}
      values -> {Enum.into(values, RDF.graph()), args}
    end
  end

  defp to_graph(nil), do: nil
  defp to_graph(%Proposition{} = proposition), do: proposition
  defp to_graph(statements), do: Graph.new(statements)

  def empty?(%{insertion: nil, deletion: nil, update: nil, replacement: nil, overwrite: nil}),
    do: true

  def empty?(%{insertion: _, deletion: _, update: _, replacement: _, overwrite: _}), do: false
  def empty?(%{insertion: nil, deletion: nil, update: nil, replacement: nil}), do: true
  def empty?(%{insertion: _, deletion: _, update: _, replacement: _}), do: false

  def empty?(args) when is_list(args) do
    args |> Keyword.take(@keys) |> Enum.empty?()
  end

  def validate(
        %{
          insertion: insertion,
          deletion: deletion,
          update: update,
          replacement: replacement,
          overwrite: overwrite
        } = changeset
      ) do
    with :ok <- do_validate(insertion, deletion, update, replacement, overwrite) do
      {:ok, changeset}
    end
  end

  defp do_validate(insertion, deletion, update, replacement, overwrite) do
    insertion = Proposition.graph(insertion)
    deletion = Proposition.graph(deletion)
    update = Proposition.graph(update)
    replacement = Proposition.graph(replacement)
    overwrite = Proposition.graph(overwrite)

    with :ok <- check_statements_presence(insertion, deletion, update, replacement, overwrite),
         :ok <- check_no_insert_delete_overlap(insertion, deletion, update, replacement),
         :ok <- check_no_inserts_overlap(insertion, update, replacement),
         :ok <- check_no_replacement_overlap(insertion, update, replacement),
         :ok <- check_no_update_overlap(insertion, update) do
      :ok
    end
  end

  defp check_statements_presence(nil, nil, nil, nil, nil),
    do: {:error, InvalidChangesetError.exception(reason: :empty)}

  defp check_statements_presence(_, _, _, _, _), do: :ok

  defp check_no_insert_delete_overlap(insertion, deletion, update, replacement) do
    overlapping_statements =
      [insertion, update, replacement]
      |> Enum.flat_map(&overlapping_statements(&1, deletion))

    if Enum.empty?(overlapping_statements) do
      :ok
    else
      {:error,
       InvalidChangesetError.exception(
         reason:
           "the following statements are in both insertion and deletions: #{inspect(overlapping_statements)}"
       )}
    end
  end

  defp check_no_inserts_overlap(insertion, update, replacement) do
    [
      {insertion, update},
      {insertion, replacement},
      {update, replacement}
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
              "the following statements are in multiple insertions: #{inspect(overlapping_statements)}"
          )}}
      end
    end)
  end

  defp check_no_replacement_overlap(_, _, nil), do: :ok

  defp check_no_replacement_overlap(insertion, update, replacement) do
    replacement
    |> Graph.subjects()
    |> Enum.find_value(fn subject ->
      cond do
        update_description = update && update[subject] ->
          {:error,
           InvalidChangesetError.exception(
             reason:
               "the following update statements overlap with replace overwrites: #{inspect(Description.triples(update_description))}"
           )}

        insert_description = insertion && insertion[subject] ->
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

  defp check_no_update_overlap(insertion, update) do
    update
    |> Graph.descriptions()
    |> Enum.find_value(fn description ->
      if insert_description = insertion && insertion[description.subject] do
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
