defmodule Ontogen.Commands.CreateSpeechActTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Commands.CreateSpeechAct
  alias Ontogen.{Local, SpeechAct}

  test "uses proper defaults" do
    assert {:ok, %SpeechAct{} = speech_act} = Ontogen.speech_act(insert: graph())

    assert speech_act.insert == proposition()
    assert DateTime.diff(DateTime.utc_now(), speech_act.time, :second) <= 1
    assert speech_act.speaker == Local.agent()
  end
end
