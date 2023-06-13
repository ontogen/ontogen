defmodule Ontogen.Commands.CreateUtteranceTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Commands.CreateUtterance
  alias Ontogen.{Local, Utterance}

  test "uses proper defaults" do
    assert {:ok, %Utterance{} = utterance} = Ontogen.utterance(insert: graph())

    assert utterance.insertion == expression()
    assert DateTime.diff(DateTime.utc_now(), utterance.time, :second) <= 1
    assert utterance.speaker == Local.agent()
  end
end
