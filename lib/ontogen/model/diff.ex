defmodule Ontogen.Diff do
  alias Ontogen.{Commit, Proposition}
  alias RDF.Graph
  alias RTC.Compound

  defstruct [:insert, :delete, :update, :replace, :overwrite]

  def new(%Commit{} = commit) do
    %__MODULE__{
      insert: to_graph(commit.insert),
      delete: to_graph(commit.delete),
      update: to_graph(commit.update),
      replace: to_graph(commit.replace),
      overwrite: to_graph(commit.overwrite)
    }
  end

  defp to_graph(nil), do: Graph.new()
  defp to_graph(%Graph{} = graph), do: graph
  defp to_graph(%Proposition{statements: compound}), do: Compound.graph(compound)
  defp to_graph(statements), do: Graph.new(statements)

  def merge_commits([first | rest]) do
    Enum.reduce(rest, new(first), &do_merge_commits(&2, &1))
  end

  def merge_commits(changeset1, changeset2) do
    changeset1
    |> new()
    |> do_merge_commits(changeset2)
  end

  defp do_merge_commits(changeset1, %Commit{} = changeset2) do
    changeset2 = new(changeset2)

    %__MODULE__{
      insert:
        changeset1.insert
        |> Graph.delete(changeset2.delete)
        |> Graph.delete(changeset2.update)
        |> Graph.delete(changeset2.replace)
        |> Graph.delete(changeset2.overwrite)
        |> Graph.add(
          changeset2.insert
          |> Graph.delete(changeset1.update)
          |> Graph.delete(changeset1.replace)
        ),
      update:
        changeset1.update
        |> Graph.delete(changeset2.delete)
        |> Graph.delete(changeset2.replace)
        |> Graph.delete(changeset2.overwrite)
        |> Graph.add(
          changeset2.update
          |> Graph.delete(changeset1.replace)
        ),
      replace:
        changeset1.replace
        |> Graph.delete(changeset2.delete)
        |> Graph.delete(changeset2.overwrite)
        |> Graph.add(changeset2.replace),
      delete:
        changeset1.delete
        |> Graph.delete(changeset2.insert)
        |> Graph.delete(changeset2.update)
        |> Graph.delete(changeset2.replace)
        |> Graph.add(changeset2.delete),
      overwrite:
        changeset1.overwrite
        |> Graph.delete(changeset2.insert)
        |> Graph.delete(changeset2.delete)
        |> Graph.delete(changeset2.update)
        |> Graph.delete(changeset2.replace)
        |> Graph.add(changeset2.overwrite)
    }
  end
end
