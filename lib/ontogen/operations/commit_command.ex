defmodule Ontogen.Operations.CommitCommand do
  use Ontogen.Command,
    params: [
      changes: nil,
      additional_prov_metadata: nil,
      on_no_effective_changes: :error,
      commit_attrs: nil
    ]

  alias Ontogen.{
    Service,
    Repository,
    Commit,
    Changeset,
    SpeechAct,
    InvalidCommitError,
    NoEffectiveChanges
  }

  alias Ontogen.Operations.EffectiveChangesetQuery
  alias Ontogen.Operations.CommitCommand.Update

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
    {additional_prov_metadata, args} = Keyword.pop(args, :additional_prov_metadata)

    with {:ok, command} <- do_new(extract_speech_act(args), Keyword.pop(args, :revert)) do
      {:ok,
       %__MODULE__{
         command
         | additional_prov_metadata:
             additional_prov_metadata && RDF.graph(additional_prov_metadata),
           on_no_effective_changes: no_effective_change_handler
       }}
    end
  end

  defp do_new({:ok, speech_act, commit_attrs}, {nil, _}) do
    {:ok, %__MODULE__{changes: speech_act, commit_attrs: commit_attrs(speech_act, commit_attrs)}}
  end

  defp do_new({:ok, _, _}, {revert, _}) when not is_nil(revert) do
    raise ArgumentError.exception("mutual exclusive speech act arguments and :revert used")
  end

  defp do_new(_, {revert, commit_attrs}) when not is_nil(revert) do
    {:ok, %__MODULE__{changes: revert, commit_attrs: commit_attrs}}
  end

  defp do_new(speech_act_error, _), do: speech_act_error

  def new!(args), do: bang!(&new/1, [args])

  defp commit_attrs(speech_act, args) do
    Keyword.put(args, :speech_act, speech_act)
  end

  defp extract_no_effective_change_handler(args) do
    case Keyword.pop(args, :on_no_effective_changes, :error) do
      {handler, args} when handler in [:error] ->
        {handler, args}

      {invalid, _} ->
        raise ArgumentError.exception(
                "invalid :on_no_effective_changes value: #{inspect(invalid)}"
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
    parent_commit = Repository.head_id(service.repository)

    with {:ok, effective_changeset} <- effective_changeset(command, service),
         {:ok, commit} <- build_commit(command, effective_changeset, parent_commit) do
      apply_commit(commit, command.additional_prov_metadata, service)
    end
  end

  defp effective_changeset(
         %__MODULE__{changes: changes, on_no_effective_changes: on_no_effective_changes},
         service
       ) do
    with {:ok, effective_changeset_query} <- EffectiveChangesetQuery.new(changes) do
      effective_changeset_query
      |> EffectiveChangesetQuery.call(service)
      |> handle_no_effective_changes(on_no_effective_changes)
    end
  end

  defp handle_no_effective_changes({:ok, %NoEffectiveChanges{} = no_effective_changes}, :error),
    do: {:error, no_effective_changes}

  defp handle_no_effective_changes(effective_changes, _), do: effective_changes

  defp build_commit(%{commit_attrs: commit_attrs}, changeset, parent_commit) do
    commit_attrs
    |> Keyword.put(:changeset, changeset)
    |> Keyword.put(:parent, parent_commit)
    |> Commit.new()
  end

  defp apply_commit(commit, additional_prov_metadata, service) do
    with {:ok, update} <- Update.build(service.repository, commit, additional_prov_metadata),
         :ok <- Service.handle_sparql(update, service, nil),
         {:ok, new_service} <- Service.set_head(service, commit) do
      {:ok, new_service, commit}
    end
  end
end
