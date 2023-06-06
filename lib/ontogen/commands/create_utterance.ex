defmodule Ontogen.Commands.CreateUtterance do
  @moduledoc """
  Creates a `Ontogen.Utterance` using defaults from the `Ontogen.Local.Config`.
  """

  alias Ontogen.{Local, Utterance}

  def call(%Utterance{} = utterance) do
    Grax.validate(utterance)
  end

  def call(args) do
    args
    |> Keyword.put_new(:speaker, Local.agent())
    |> Keyword.put_new(:ended_at, DateTime.utc_now())
    |> Utterance.new()
  end

  def call!(args) do
    case call(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end
end
