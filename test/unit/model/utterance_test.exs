defmodule Ontogen.UtteranceTest do
  use Ontogen.Test.Case

  doctest Ontogen.Utterance

  alias Ontogen.{Utterance, InvalidUtteranceError}

  describe "new/1" do
    test "with all required attributes" do
      assert {:ok, %Utterance{} = utterance} =
               Utterance.new(
                 insertion: graph(),
                 speaker: agent(),
                 data_source: dataset(),
                 ended_at: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = utterance.__id__

      assert utterance.insertion == expression()
      assert utterance.ended_at == datetime()
      assert utterance.speaker == agent()
      assert utterance.data_source == dataset()
    end

    test "without statements" do
      assert Utterance.new(
               speaker: agent(),
               data_source: dataset(),
               ended_at: datetime()
             ) ==
               {:error, InvalidUtteranceError.exception(reason: "no statements")}
    end
  end

  describe "Grax.to_rdf/1" do
    test "is as compact as possible" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(utterance())

      refute Graph.include?(graph, {utterance().__id__, RDF.type(), Og.Utterance})
    end
  end

  test "RDF roundtrip" do
    utterance = utterance()
    assert {:ok, %Graph{} = graph} = Grax.to_rdf(utterance)

    assert Utterance.load(graph, utterance.__id__, depth: 1) ==
             {:ok, utterance}
  end
end
