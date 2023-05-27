defmodule Ontogen.Commands.CreateUtterance do
  @moduledoc """
  Creates a `Ontogen.Utterance` using defaults from the `Ontogen.Local.Config`.
  """

  alias Ontogen.{Local, Utterance}

  def call(args) do
    args
    |> Keyword.put_new(:was_associated_with, Local.agent())
    |> Keyword.put_new(:ended_at, DateTime.utc_now())
    |> Utterance.new()
    |> case do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end
end
