defmodule Ontogen.LogType.Native do
  @behaviour Ontogen.LogType

  alias Ontogen.NS.Og
  alias Ontogen.Commit
  alias RDF.Graph

  import RDF.Utils, only: [map_while_ok: 2]

  @impl true
  def log(history_graph, _, _opts \\ []) do
    with {:ok, commits} <-
           history_graph
           |> Graph.descriptions()
           |> Enum.filter(&commit?/1)
           |> map_while_ok(&Commit.load(history_graph, &1.subject)) do
      {:ok, Enum.sort_by(commits, & &1.ended_at, {:desc, DateTime})}
    end
  end

  defp commit?(description), do: !!description[Og.committer()]
end
