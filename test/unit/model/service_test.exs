defmodule Ontogen.ServiceTest do
  use Ontogen.StoreCase

  doctest Ontogen.Service

  alias Ontogen.{Service, Manifest}
  alias Gno.Store.SPARQL.Operation

  test "graph/1" do
    assert Service.graph(Manifest.service!(), :history) == Manifest.history!()
    assert Service.graph(Manifest.service!(), Manifest.history_id()) == Manifest.history!()
  end

  test "has_graph?/2" do
    assert Service.has_graph?(Manifest.service!(), :history)
    assert Service.has_graph?(Manifest.service!(), Manifest.history_id())
  end

  test "graph_name/2" do
    assert Service.graph_name(Manifest.service!(), :history) == Manifest.history_id()
    assert Service.graph_name(Manifest.service!(), Manifest.history_id()) == Manifest.history_id()
  end

  describe "handle/4" do
    test "default graph" do
      assert EX.S
             |> EX.p(EX.O)
             |> RDF.graph()
             |> Operation.insert_data!()
             |> Service.handle_sparql(Manifest.service!(), graph: nil) ==
               :ok

      assert {:ok,
              %SPARQL.Query.Result{
                results: [
                  %{
                    "s" => ~I<http://example.com/S>,
                    "p" => ~I<http://example.com/p>,
                    "o" => ~I<http://example.com/O>
                  }
                ]
              }} =
               "SELECT * WHERE { ?s ?p ?o . }"
               |> Operation.select!()
               |> Service.handle_sparql(Manifest.service!(), graph: nil)
    end

    test "named graph" do
      assert EX.S
             |> EX.p(EX.O)
             |> RDF.graph()
             |> Operation.insert_data!()
             |> Service.handle_sparql(Manifest.service!(), graph: :primary) ==
               :ok

      assert {:ok,
              %SPARQL.Query.Result{
                results: [
                  %{
                    "s" => ~I<http://example.com/S>,
                    "p" => ~I<http://example.com/p>,
                    "o" => ~I<http://example.com/O>
                  }
                ]
              }} =
               "SELECT * WHERE { ?s ?p ?o . }"
               |> Operation.select!()
               |> Service.handle_sparql(Manifest.service!(), graph: :primary)

      graph =
        EX.S2
        |> EX.p(EX.O2)
        |> RDF.graph()

      assert graph
             |> Operation.insert_data!()
             |> Service.handle_sparql(Manifest.service!(), graph: :repository_manifest) ==
               :ok

      assert "CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o . }"
             |> Operation.construct!()
             |> Service.handle_sparql(Manifest.service!(), graph: :repository_manifest) ==
               {:ok, graph}
    end
  end
end
