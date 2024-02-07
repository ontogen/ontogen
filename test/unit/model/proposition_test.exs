defmodule Ontogen.PropositionTest do
  use OntogenCase

  doctest Ontogen.Proposition

  alias Ontogen.{Proposition, IdGenerationError}
  alias RTC.Compound

  describe "new/1" do
    test "with a graph of statements" do
      assert {:ok, %Proposition{} = proposition} = Proposition.new(graph())
      assert proposition.__id__ == Ontogen.IdUtils.dataset_hash_iri!(graph())
      assert Compound.graph(proposition.statements) == graph()
    end

    test "without statements" do
      assert Proposition.new(RDF.graph()) ==
               {:error, IdGenerationError.exception(reason: "empty dataset")}
    end
  end

  test "graph/1" do
    assert Proposition.graph(proposition()) == graph()
  end

  describe "Grax.to_rdf/1" do
    test "includes the statements as a compound" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(proposition())

      assert Graph.include?(
               graph,
               RTC.Compound.to_rdf(proposition().statements, element_style: :elements)
             )
    end

    test "is as compact as possible" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(proposition())

      refute Graph.include?(graph, {id(:proposition), RDF.type(), Og.Proposition})
    end
  end

  test "RDF roundtrip" do
    proposition = proposition()
    assert {:ok, %Graph{} = graph} = Grax.to_rdf(proposition)

    assert Proposition.load(graph, proposition.__id__) ==
             {:ok, proposition}
  end
end
