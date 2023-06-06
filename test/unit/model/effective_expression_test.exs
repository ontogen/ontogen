defmodule Ontogen.EffectiveExpressionTest do
  use Ontogen.Test.Case

  doctest Ontogen.EffectiveExpression

  alias Ontogen.{EffectiveExpression, IdGenerationError}
  alias RTC.Compound

  describe "new/1" do
    test "with a graph of statements" do
      assert {:ok, %EffectiveExpression{} = effective_expression} =
               EffectiveExpression.new(expression(), subgraph())

      assert %IRI{value: "urn:hash::sha256:" <> _} = effective_expression.__id__
      assert effective_expression.origin == expression()
      assert Compound.graph(effective_expression.statements) == subgraph()
    end

    test "without statements" do
      assert EffectiveExpression.new(expression(), RDF.graph()) ==
               {:error, IdGenerationError.exception(reason: "empty dataset")}
    end

    test "with statements not part of the origin expression" do
      assert EffectiveExpression.new(
               expression(),
               subgraph() |> Graph.add(EX.S3 |> EX.p3(EX.O3))
             ) ==
               {:error, :no_subset_of_origin}
    end

    test "with the same statements than the origin expression" do
      assert EffectiveExpression.new(expression(), graph()) ==
               {:ok, expression()}

      assert EffectiveExpression.new(expression(), graph() |> Graph.change_name(EX.Other)) ==
               {:ok, expression()}

      assert EffectiveExpression.new(expression(), graph() |> Graph.add_prefixes(other: EX.Other)) ==
               {:ok, expression()}
    end

    test "has a different id than a normal expression with the same statements" do
      graph_with_additional_statement = graph() |> Graph.add(EX.S3 |> EX.p3(EX.O3))

      assert {:ok, %EffectiveExpression{} = effective_expression} =
               EffectiveExpression.new(expression(graph_with_additional_statement), graph())

      assert effective_expression.__id__ != expression(graph()).__id__
    end
  end

  test "graph/1" do
    assert EffectiveExpression.graph(effective_expression()) == subgraph()
  end

  describe "Grax.to_rdf/1" do
    test "includes to statements as a compound" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(effective_expression())

      assert Graph.include?(
               graph,
               RTC.Compound.to_rdf(effective_expression().statements, element_style: :elements)
             )
    end
  end

  test "RDF roundtrip" do
    expression = effective_expression()
    assert {:ok, %Graph{} = graph} = Grax.to_rdf(expression)

    assert EffectiveExpression.load(graph, expression.__id__) ==
             {:ok, expression}
  end
end
