defmodule Ontogen.ServiceTest do
  use Ontogen.StoreCase

  doctest Ontogen.Service

  alias Ontogen.{Service, Manifest}
  alias Gno.Store.SPARQL.Operation

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
             |> Service.handle_sparql(Manifest.service!(), graph: :dataset) ==
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
               |> Service.handle_sparql(Manifest.service!(), graph: :dataset)

      graph =
        EX.S2
        |> EX.p(EX.O2)
        |> RDF.graph()

      assert graph
             |> Operation.insert_data!()
             |> Service.handle_sparql(Manifest.service!(), graph: :repo) ==
               :ok

      assert "CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o . }"
             |> Operation.construct!()
             |> Service.handle_sparql(Manifest.service!(), graph: :repo) ==
               {:ok, graph}
    end
  end
end
