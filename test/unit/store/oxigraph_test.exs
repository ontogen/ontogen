defmodule Ontogen.Store.OxigraphTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Store.Oxigraph

  alias Ontogen.Store.Oxigraph

  test "inserting data to the default graph" do
    assert {:ok, %SPARQL.Query.Result{results: []}} =
             Oxigraph.query(Local.store(), nil, "SELECT * WHERE {?s ?p ?o}")

    assert Oxigraph.insert_data(Local.store(), nil, EX.S |> EX.p(42)) == :ok

    assert {:ok,
            %SPARQL.Query.Result{
              results: [
                %{
                  "s" => ~I<http://example.com/S>,
                  "p" => ~I<http://example.com/p>,
                  "o" => _
                }
              ]
            }} = Oxigraph.query(Local.store(), nil, "SELECT * WHERE {?s ?p ?o}")
  end

  test "inserting data to a named graph" do
    graph = EX.Graph

    assert {:ok, %SPARQL.Query.Result{results: []}} =
             Oxigraph.query(Local.store(), graph, "SELECT * WHERE {?s ?p ?o}")

    assert Oxigraph.insert_data(Local.store(), graph, EX.S |> EX.p(42)) == :ok

    assert {:ok,
            %SPARQL.Query.Result{
              results: [
                %{
                  "s" => ~I<http://example.com/S>,
                  "p" => ~I<http://example.com/p>,
                  "o" => _
                }
              ]
            }} = Oxigraph.query(Local.store(), graph, "SELECT * WHERE {?s ?p ?o}")
  end
end
