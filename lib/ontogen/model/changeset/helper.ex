defmodule Ontogen.Changeset.Helper do
  @moduledoc !"Shared functions between `Ontogen.SpeechAct.Changeset` and `Ontogen.Commit.Changeset`."

  alias Ontogen.{Proposition, InvalidChangesetError}
  alias Ontogen.Changeset.Action
  alias Ontogen.NS.Og
  alias RDF.{Graph, Dataset}

  def to_graph(nil), do: nil
  def to_graph([]), do: nil
  def to_graph(%Graph{} = graph), do: graph
  def to_graph(%Proposition{} = proposition), do: Proposition.graph(proposition)
  def to_graph(statements), do: Graph.new(statements)

  def inserts(%{add: add, update: update, replace: replace}) do
    [add, update, replace]
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&Graph.subject_count/1)
    |> case do
      [] -> Graph.new()
      [graph] -> graph
      [largest | rest] -> Enum.reduce(rest, largest, &Graph.add(&2, &1))
    end
  end

  def deletes(%{remove: nil}), do: Graph.new()
  def deletes(%{remove: remove}), do: remove

  def overwrites(%{overwrite: nil}), do: Graph.new()
  def overwrites(%{overwrite: overwrite}), do: overwrite
  def overwrites(%{}), do: Graph.new()

  def extract(type, keywords) when is_list(keywords) do
    {actions, keywords} = Action.extract(keywords)

    case Keyword.pop(keywords, :changeset) do
      {nil, keywords} ->
        with {:ok, changeset} <- type.new(actions, keywords) do
          {:ok, changeset, keywords}
        end

      {changeset, keywords} ->
        if Action.empty?(actions) do
          with {:ok, changeset} <- to_changeset(type, changeset, keywords) do
            {:ok, changeset, keywords}
          end
        else
          {:error,
           InvalidChangesetError.exception(
             reason: ":changeset can not be used along additional changes"
           )}
        end
    end
  end

  defp to_changeset(type, %type{} = changeset, opts), do: type.validate(changeset, opts)

  defp to_changeset(type, changeset, opts) do
    type
    |> struct!(changeset)
    |> Map.from_struct()
    |> type.new(opts)
  end

  def copy_to_proposition_struct(changeset, struct) do
    with_propositions =
      changeset
      |> Map.from_struct()
      |> Enum.map(fn
        {action, %Graph{} = graph} -> {action, Proposition.new!(graph)}
        {_, nil} = empty -> empty
      end)

    struct(struct, with_propositions)
  end

  def to_rdf(%_type{overwrite: overwrite} = changeset) do
    changeset
    |> Map.delete(:overwrite)
    |> to_rdf()
    |> dataset_add(overwrite, graph: Og.Overwrite)
  end

  def to_rdf(%_type{} = changeset) do
    Dataset.new()
    |> dataset_add(changeset.add, graph: Og.Addition)
    |> dataset_add(changeset.remove, graph: Og.Removal)
    |> dataset_add(changeset.update, graph: Og.Update)
    |> dataset_add(changeset.replace, graph: Og.Replacement)
  end

  def from_rdf(%Dataset{} = dataset, type, opts \\ []) do
    type.new!(
      %{
        add: dataset |> Dataset.graph(Og.Addition) |> reset_name(),
        update: dataset |> Dataset.graph(Og.Update) |> reset_name(),
        replace: dataset |> Dataset.graph(Og.Replacement) |> reset_name(),
        remove: dataset |> Dataset.graph(Og.Removal) |> reset_name(),
        overwrite: dataset |> Dataset.graph(Og.Overwrite) |> reset_name()
      },
      opts
    )
  end

  def graph_add(nil, additions), do: graph_cleanup(additions)
  def graph_add(graph, nil), do: graph_cleanup(graph)
  def graph_add(graph, additions), do: Graph.add(graph, additions)
  def graph_delete(nil, _), do: nil
  def graph_delete(graph, nil), do: graph_cleanup(graph)
  def graph_delete(graph, removals), do: graph |> Graph.delete(removals) |> graph_cleanup()
  def graph_intersection(nil, _), do: Graph.new()
  def graph_intersection(graph1, graph2), do: Graph.intersection(graph1, graph2)
  def graph_cleanup(nil), do: nil
  def graph_cleanup(graph), do: unless(Graph.empty?(graph), do: graph)

  defp dataset_add(dataset, nil, _), do: dataset
  defp dataset_add(dataset, additions, opts), do: Dataset.add(dataset, additions, opts)
  defp reset_name(nil), do: nil
  defp reset_name(graph), do: Graph.change_name(graph, nil)
end
