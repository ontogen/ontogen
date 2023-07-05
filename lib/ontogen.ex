defmodule Ontogen do
  defdelegate speech_act(args), to: Ontogen.Commands.CreateSpeechAct, as: :call
  defdelegate speech_act!(args), to: Ontogen.Commands.CreateSpeechAct, as: :call!
end
