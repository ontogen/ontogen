defmodule Ontogen.HistoryType.Native do
  @behaviour Ontogen.HistoryType

  alias Ontogen.NS.Og
  alias Ontogen.Commit
  alias RDF.Graph

  import RDF.Utils, only: [map_while_ok: 2]

  # Note, that this default is in practice always overwritten by the default ordering set in the HistoryQuery
  @default_order {:desc, DateTime}

  @impl true
  def history(history_graph, _, _, opts \\ []) do
    with {:ok, commits} <-
           history_graph
           |> Graph.descriptions()
           |> Enum.filter(&commit?/1)
           |> map_while_ok(&Commit.load(history_graph, &1.subject)) do
      {:ok, sort(commits, Keyword.get(opts, :order))}
    end
  end

  defp commit?(description), do: !!description[Og.committer()]

  defp sort(commits, nil), do: sort(commits, @default_order)
  defp sort(commits, {direction, :time}), do: sort(commits, {direction, DateTime})

  defp sort(commits, {_, DateTime} = order) do
    Enum.sort_by(commits, & &1.time, order)
  end

  defp sort(commits, {:asc, :parent, commit_id_chain}) do
    commits |> sort({:desc, :parent, commit_id_chain}) |> Enum.reverse()
  end

  defp sort(commits, {:desc, :parent, commit_id_chain}) do
    commit_idx = Map.new(commits, &{&1.__id__, &1})
    Enum.flat_map(commit_id_chain, &List.wrap(commit_idx[&1]))
  end

  defp sort(_, invalid) do
    raise ArgumentError, "invalid history order: #{inspect(invalid)}"
  end
end
