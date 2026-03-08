defmodule Ontogen.Operations.CommitCommand do
  use Ontogen.Operation.Command,
    params: [
      changes: nil,
      commit_type: nil,
      additional_metadata: nil,
      on_no_effective_changes: nil,
      commit_attrs: nil
    ]

  alias Ontogen.{SpeechAct, InvalidCommitError}
  alias Gno.Changeset

  import Ontogen.Utils, only: [bang!: 2]

  api do
    def commit(args) do
      args
      |> CommitCommand.new()
      |> CommitCommand.__do_call__()
    end

    def commit!(args \\ []), do: bang!(&commit/1, [args])
  end

  def new(args) do
    {no_effective_change_handler, args} = extract_no_effective_change_handler(args)
    {additional_metadata, args} = Keyword.pop(args, :additional_metadata)

    with {:ok, command} <- do_new(extract_speech_act(args), Keyword.pop(args, :revert)) do
      {:ok,
       %{
         command
         | additional_metadata: additional_metadata && RDF.graph(additional_metadata),
           on_no_effective_changes: no_effective_change_handler
       }}
    end
  end

  defp do_new({:ok, speech_act, commit_attrs}, {nil, _}) do
    {:ok,
     %__MODULE__{
       commit_type: :speech_act,
       changes: speech_act,
       commit_attrs: commit_attrs(speech_act, commit_attrs)
     }}
  end

  defp do_new({:ok, _, _}, {revert, _}) when not is_nil(revert) do
    raise ArgumentError.exception("mutual exclusive speech act arguments and :revert used")
  end

  defp do_new(_, {revert, commit_attrs}) when not is_nil(revert) do
    {:ok,
     %__MODULE__{
       commit_type: :revert,
       changes: revert,
       commit_attrs: commit_attrs
     }}
  end

  defp do_new(speech_act_error, _), do: speech_act_error

  def new!(args), do: bang!(&new/1, [args])

  defp commit_attrs(speech_act, args) do
    Keyword.put(args, :speech_act, speech_act)
  end

  defp extract_no_effective_change_handler(args) do
    case Keyword.pop(args, :on_no_effective_changes, nil) do
      {nil, args} ->
        {nil, args}

      {handler, args} when handler in ~w[error skip]a ->
        {to_string(handler), args}

      {invalid, _} ->
        raise ArgumentError.exception(
                "Invalid :on_no_effective_changes value: #{inspect(invalid)}"
              )
    end
  end

  defp extract_speech_act(args) do
    {speech_act_args, args} = Keyword.pop(args, :speech_act)

    cond do
      match?(%SpeechAct{}, speech_act_args) && Changeset.Action.empty?(args) ->
        {:ok, speech_act_args, args}

      speech_act_args && Changeset.Action.empty?(args) ->
        with {:ok, speech_act} <- SpeechAct.new(speech_act_args) do
          {:ok, speech_act, args}
        end

      speech_act_args ->
        {:error,
         InvalidCommitError.exception(reason: "speech acts are not allowed with other changes")}

      true ->
        SpeechAct.extract(args)
    end
  end

  @impl true
  def call(%__MODULE__{} = command, service) do
    with {:ok, processor} <- Gno.Commit.Processor.new(service),
         {:ok, commit, processor} <- Gno.Commit.Processor.execute(processor, command) do
      {:ok, processor.service, commit}
    else
      {:error, %Gno.Commit.ProcessorError{processor: %{errors: [error]}}} -> {:error, error}
      error -> error
    end
  end
end
