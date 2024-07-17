defmodule Ontogen.SpeechActTest do
  use OntogenCase

  doctest Ontogen.SpeechAct

  alias Ontogen.{SpeechAct, Config, InvalidChangesetError}

  test "id stability" do
    assert {:ok,
            %SpeechAct{
              __id__: %IRI{
                value:
                  "urn:hash::sha256:7db02c9a3d9a65a3272cfeb8dc7a1df97d3dbfb6db832f96f50fe3a79c5e6d1e"
              }
            }} =
             SpeechAct.new(
               add: graph(1),
               update: graph(2),
               replace: graph(3),
               remove: graph(4),
               speaker: agent(),
               time: datetime()
             )

    assert {:ok,
            %SpeechAct{
              __id__: %IRI{
                value:
                  "urn:hash::sha256:0ccd1c7cda0f51664fe1932a7f020df62dadbd15180f774e381d0e5748f24d5e"
              }
            }} =
             SpeechAct.new(
               add: graph(1),
               speaker: agent(),
               time: datetime()
             )

    assert {:ok,
            %SpeechAct{
              __id__: %IRI{
                value:
                  "urn:hash::sha256:1cc91da9ebdd4bb82de6768c6ad0a19e231b057228fd07820b58a5b9ad8229cd"
              }
            }} =
             SpeechAct.new(
               add: graph(1),
               update: graph(2),
               replace: graph(3),
               remove: graph(4),
               data_source: id(:dataset),
               speaker: nil,
               time: datetime()
             )
  end

  describe "new/1" do
    test "with all required attributes" do
      assert {:ok, %SpeechAct{} = speech_act} =
               SpeechAct.new(
                 add: graph(),
                 speaker: agent(),
                 data_source: id(:dataset),
                 time: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = speech_act.__id__

      assert speech_act.add == proposition()
      assert speech_act.time == datetime()
      assert speech_act.speaker == agent()
      assert speech_act.data_source == id(:dataset)
    end

    test "uses proper defaults" do
      assert {:ok, %SpeechAct{} = speech_act} = SpeechAct.new(add: graph())

      assert speech_act.add == proposition()
      assert DateTime.diff(DateTime.utc_now(), speech_act.time, :second) <= 1
      assert speech_act.speaker == Config.user!()
    end

    test "without statements" do
      assert SpeechAct.new(
               speaker: agent(),
               data_source: id(:dataset),
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
