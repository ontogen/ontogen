defmodule Ontogen do
  defdelegate utterance(args), to: Ontogen.Commands.CreateUtterance, as: :call
  defdelegate utterance!(args), to: Ontogen.Commands.CreateUtterance, as: :call!
end
