defmodule Ontogen.Commands.CreateSpeechAct do
  @moduledoc """
  Creates a `Ontogen.SpeechAct` using defaults from the `Ontogen.Local.Config`.
  """

  alias Ontogen.{Local, SpeechAct, Changeset, Utils}

  @args_keys Changeset.keys() ++ [:speaker, :speech_act_time, :data_source]
  @shared_args [:time, :committer]

  def call(%SpeechAct{} = speech_act) do
    Grax.validate(speech_act)
  end

  def call(args) do
    {commit_args, args} = Utils.extract_args(args, @shared_args)
    {speech_act_time, args} = Keyword.pop(args, :speech_act_time)

    args
    |> Keyword.put_new(
      :speaker,
      Keyword.get_lazy(commit_args, :committer, fn -> Local.agent() end)
    )
    |> Keyword.put(
      :time,
      speech_act_time || Keyword.get_lazy(commit_args, :time, fn -> DateTime.utc_now() end)
    )
    |> SpeechAct.new()
  end

  def call!(args) do
    case call(args) do
      {:ok, speech_act} -> speech_act
      {:error, error} -> raise error
    end
  end

  def extract(args) do
    {speech_act_args, args} = extract_args(args)

    with {:ok, speech_act} <- call(speech_act_args) do
      {:ok, speech_act, args}
    end
  end

  defp extract_args(args) do
    Utils.extract_args(args, @args_keys, @shared_args)
  end
end
