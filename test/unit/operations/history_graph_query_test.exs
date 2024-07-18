defmodule Ontogen.Operations.HistoryGraphQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.HistoryGraphQuery

  setup do
    init_commit_history()

    :ok
  end

  test "returns the history graph" do
    assert {:ok, %RDF.Graph{} = graph} = Ontogen.history()
    assert [_] = RDF.Graph.query(graph, {:commit?, Og.commitMessage(), "Initial commit"})
  end
end
