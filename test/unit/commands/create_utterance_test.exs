defmodule Ontogen.Commands.CreateUtteranceTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Commands.CreateUtterance
  alias Ontogen.{Local, Utterance}

  test "uses proper defaults" do
    assert %Utterance{} = utterance = Ontogen.utterance(insertion: graph())

    assert utterance.insertion == expression()
    assert DateTime.diff(DateTime.utc_now(), utterance.ended_at, :second) <= 1
    assert utterance.was_associated_with == [Local.agent()]
  end
end
