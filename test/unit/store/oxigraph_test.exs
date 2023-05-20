defmodule Ontogen.Store.OxigraphTest do
  use Ontogen.Test.Case

  doctest Ontogen.Store.Oxigraph

  alias Ontogen.Store.Oxigraph
  alias Ontogen.Local

  setup :clean_store!

  test "inserting data" do
    assert {:ok, %SPARQL.Query.Result{results: []}} =
             Oxigraph.query(Local.store(), "SELECT * WHERE {?s ?p ?o}")

    assert Oxigraph.insert_data(Local.store(), EX.S |> EX.p(42)) == :ok

    assert {:ok,
            %SPARQL.Query.Result{
              results: [
                %{
                  "s" => ~I<http://example.com/S>,
                  "p" => ~I<http://example.com/p>,
                  "o" => _
                }
              ]
            }} = Oxigraph.query(Local.store(), "SELECT * WHERE {?s ?p ?o}")
  end

  def clean_store!(_) do
    Oxigraph.delete(
      Local.store(),
      """
      DELETE { ?s ?p ?o }
      WHERE  { ?s ?p ?o . }
      """
    )
  end
end
