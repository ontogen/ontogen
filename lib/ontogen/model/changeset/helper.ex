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

  def extract(type, keywords) when is_list(keywords) do
    {actions, keywords} = Action.extract(keywords)

    case Keyword.pop(keywords, :changeset) do
      {nil, keywords} ->
        with {:ok, changeset} <- type.new(actions) do
          {:ok, changeset, keywords}
        end

      {changeset, keywords} ->
        if Action.empty?(actions) do
          with {:ok, changeset} <- to_changeset(type, changeset) do
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

  defp to_changeset(type, %type{} = changeset), do: type.validate(changeset)

  defp to_changeset(type, changeset) do
    type
    |> struct!(changeset)
    |> Map.from_struct()
    |> type.new()
  end

  def copy_to_proposition_struct(changeset, struct) do
    with_propositions =
      changeset
      |> Map.from_struct()
      |> Enum.flat_map(fn
        {action, %Graph{} = graph} -> [{action, Proposition.new!(graph)}]
        _ -> []
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

  def from_rdf(%Dataset{} = dataset, type) do
    type.new!(%{
      add: dataset |> Dataset.graph(Og.Addition) |> reset_name(),
      update: dataset |> Dataset.graph(Og.Update) |> reset_name(),
      replace: dataset |> Dataset.graph(Og.Replacement) |> reset_name(),
      remove: dataset |> Dataset.graph(Og.Removal) |> reset_name(),
      overwrite: dataset |> Dataset.graph(Og.Overwrite) |> reset_name()
    })
  end

  defp dataset_add(dataset, nil, _), do: dataset
  defp dataset_add(dataset, additions, opts), do: Dataset.add(dataset, additions, opts)
  defp reset_name(nil), do: nil
  defp reset_name(graph), do: Graph.change_name(graph, nil)
end
