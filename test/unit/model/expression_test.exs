defmodule Ontogen.ExpressionTest do
  use Ontogen.Test.Case

  doctest Ontogen.Expression

  alias Ontogen.{Expression, IdGenerationError}
  alias RTC.Compound

  describe "new/1" do
    test "with a graph of statements" do
      assert {:ok, %Expression{} = expression} = Expression.new(graph())
      assert expression.__id__ == Ontogen.IdUtils.dataset_hash_iri!(graph())
      assert Compound.graph(expression.statements) == graph()
    end

    test "without statements" do
      assert Expression.new(RDF.graph()) ==
               {:error, IdGenerationError.exception(reason: "empty dataset")}
    end
  end

  test "graph/1" do
    assert Expression.graph(expression()) == graph()
  end

  describe "Grax.to_rdf/1" do
    test "includes to statements as a compound" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(expression())

      assert Graph.include?(
               graph,
               RTC.Compound.to_rdf(expression().statements, element_style: :elements)
             )
    end

    test "is as compact as possible" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(expression())

      refute Graph.include?(graph, {id(:expression), RDF.type(), Og.Expression})
    end
  end

  test "RDF roundtrip" do
    expression = expression()
    assert {:ok, %Graph{} = graph} = Grax.to_rdf(expression)

    assert Expression.load(graph, expression.__id__) ==
             {:ok, expression}
  end
end
