defmodule Ontogen.SpeechActTest do
  use OntogenCase

  doctest Ontogen.SpeechAct

  alias Ontogen.{SpeechAct, Config, InvalidChangesetError}

  describe "new/1" do
    test "with all required attributes" do
      assert {:ok, %SpeechAct{} = speech_act} =
               SpeechAct.new(
                 add: graph(),
                 speaker: agent(),
                 data_source: dataset(),
                 time: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = speech_act.__id__

      assert speech_act.add == proposition()
      assert speech_act.time == datetime()
      assert speech_act.speaker == agent()
      assert speech_act.data_source == dataset()
    end

    test "uses proper defaults" do
      assert {:ok, %SpeechAct{} = speech_act} = SpeechAct.new(add: graph())

      assert speech_act.add == proposition()
      assert DateTime.diff(DateTime.utc_now(), speech_act.time, :second) <= 1
      assert speech_act.speaker == Config.user()
    end

    test "without statements" do
      assert SpeechAct.new(
               speaker: agent(),
               data_source: dataset(),
               time: datetime()
             ) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end
  end

  describe "Grax.to_rdf/1" do
    test "is as compact as possible" do
      assert {:ok, %Graph{} = graph} = Grax.to_rdf(speech_act())

      refute Graph.include?(graph, {speech_act().__id__, RDF.type(), Og.SpeechAct})
    end
  end

  test "RDF roundtrip" do
    speech_act = speech_act()
    assert {:ok, %Graph{} = graph} = Grax.to_rdf(speech_act)

    assert SpeechAct.load(graph, speech_act.__id__, depth: 1) ==
             {:ok, speech_act}
  end
end
