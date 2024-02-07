defmodule Ontogen.Operations.ProvGraphQueryTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.ProvGraphQuery

  setup do
    init_commit_history()

    :ok
  end

  test "returns the prov graph" do
    assert {:ok, %RDF.Graph{} = graph} = Ontogen.prov_graph()
    assert [_] = RDF.Graph.query(graph, {:commit?, Og.commitMessage(), "Initial commit"})
  end
end
