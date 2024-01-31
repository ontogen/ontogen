defmodule Ontogen.Changeset do

  alias Ontogen.{Proposition, Action, SpeechAct, InvalidChangesetError}
  alias RDF.{Graph, Description}

  defstruct Action.fields()

  @type t :: %__MODULE__{
          insert: Proposition.t() | nil,
          delete: Proposition.t() | nil,
          update: Proposition.t() | nil,
          replace: Proposition.t() | nil,
          overwrite: Proposition.t() | nil
        }

  def new(%__MODULE__{} = changeset) do
    validate(changeset)
  end

  def new(%SpeechAct{} = speech_act) do
    __MODULE__
    |> struct(Map.from_struct(speech_act))
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
             {:ok, insert} <- build_proposition(insert),
             {:ok, delete} <- build_proposition(delete),
             {:ok, update} <- build_proposition(update),
             {:ok, replace} <- build_proposition(replace),
             {:ok, overwrite} <- build_proposition(overwrite) do
          {:ok,
           %__MODULE__{
             insert: insert,
             delete: delete,
             update: update,
             replace: replace,
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

  def empty?(%{insert: nil, delete: nil, update: nil, replace: nil, overwrite: nil}),
    do: true

  def empty?(%{insert: _, delete: _, update: _, replace: _, overwrite: _}), do: false
  def empty?(%{insert: nil, delete: nil, update: nil, replace: nil}), do: true
  def empty?(%{insert: _, delete: _, update: _, replace: _}), do: false

  def empty?(args) when is_list(args) do
    args |> Keyword.take(Action.fields()) |> Enum.empty?()
  end

  def validate(
        %{
          insert: insert,
          delete: delete,
          update: update,
          replace: replace,
          overwrite: overwrite
        } = changeset
      ) do
    with :ok <- do_validate(insert, delete, update, replace, overwrite) do
      {:ok, changeset}
    end
  end

  defp do_validate(insert, delete, update, replace, overwrite) do
    insert = Proposition.graph(insert)
    delete = Proposition.graph(delete)
    update = Proposition.graph(update)
    replace = Proposition.graph(replace)
    overwrite = Proposition.graph(overwrite)

    with :ok <- check_statements_presence(insert, delete, update, replace, overwrite),
         :ok <- check_no_insert_delete_overlap(insert, delete, update, replace),
         :ok <- check_no_inserts_overlap(insert, update, replace),
         :ok <- check_no_replace_overlap(insert, update, replace),
         :ok <- check_no_update_overlap(insert, update) do
      :ok
    end
  end

  defp check_statements_presence(nil, nil, nil, nil, nil),
    do: {:error, InvalidChangesetError.exception(reason: :empty)}

  defp check_statements_presence(_, _, _, _, _), do: :ok

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
