defmodule Ontogen.Commands.CreateUtterance do
  @moduledoc """
  Creates a `Ontogen.Utterance` using defaults from the `Ontogen.Local.Config`.
  """

  alias Ontogen.{Local, Utterance, Changeset, Utils}

  @args_keys Changeset.keys() ++ [:speaker, :utterance_time, :data_source]
  @shared_args [:time, :committer]

  def call(%Utterance{} = utterance) do
    Grax.validate(utterance)
  end

  def call(args) do
    {commit_args, args} = Utils.extract_args(args, @shared_args)
    {utterance_time, args} = Keyword.pop(args, :utterance_time)

    args
    |> Keyword.put_new(
      :speaker,
      Keyword.get_lazy(commit_args, :committer, fn -> Local.agent() end)
    )
    |> Keyword.put(
      :time,
      utterance_time || Keyword.get_lazy(commit_args, :time, fn -> DateTime.utc_now() end)
    )
    |> Utterance.new()
  end

  def call!(args) do
    case call(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  def extract(args) do
    {utterance_args, args} = extract_args(args)

    with {:ok, utterance} <- call(utterance_args) do
      {:ok, utterance, args}
    end
  end

  defp extract_args(args) do
    Utils.extract_args(args, @args_keys, @shared_args)
  end
end
