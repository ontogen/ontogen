defmodule Ontogen.Operations.GraphQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.GraphQuery

  setup do
    init_commit_history()

    :ok
  end

  describe "graph/1" do
    test "returns the specified graph" do
      assert Ontogen.graph(:dataset) == {:ok, graph()}

      assert Ontogen.graph(Ontogen.Manifest.dataset_id()) ==
               {:ok, graph()}

      assert {:ok, %RDF.Graph{}} = Ontogen.graph(:history)
    end
  end

  describe "dataset/0" do
    test "returns the dataset" do
      assert Ontogen.dataset() == {:ok, graph()}
    end
  end
end
