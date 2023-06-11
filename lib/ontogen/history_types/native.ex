defmodule Ontogen.HistoryType.Native do
  @behaviour Ontogen.HistoryType

  alias Ontogen.NS.Og
  alias Ontogen.Commit
  alias RDF.Graph

  import RDF.Utils, only: [map_while_ok: 2]

  @impl true
  def history(history_graph, _, _opts \\ []) do
    with {:ok, commits} <-
           history_graph
           |> Graph.descriptions()
           |> Enum.filter(&commit?/1)
           |> map_while_ok(&Commit.load(history_graph, &1.subject)) do
      {:ok, Enum.sort_by(commits, & &1.time, {:desc, DateTime})}
    end
  end

  defp commit?(description), do: !!description[Og.committer()]
end
