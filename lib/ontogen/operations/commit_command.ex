defmodule Ontogen.Operations.CommitCommand do
  use Ontogen.Command,
    params: [
      speech_act: nil,
      on_no_effective_changes: :error,
      commit_attrs: nil
    ]

  alias Ontogen.{
    Store,
    Repository,
    Commit,
    Changeset,
    SpeechAct,
    Config,
    InvalidCommitError
  }

  alias Ontogen.Operations.EffectiveChangesetQuery
  alias Ontogen.Operations.CommitCommand.Update

  api do
    def commit(args) do
      args
      |> CommitCommand.new()
      |> CommitCommand.__do_call__()
    end
  end

  def new(args) do
    with {:ok, no_effective_change_handler, args} <- extract_no_effective_change_handler(args),
         {:ok, speech_act, args} <- extract_speech_act(args) do
      {:ok,
       %__MODULE__{
         speech_act: speech_act,
         on_no_effective_changes: no_effective_change_handler,
         commit_attrs: args
       }}
    end
  end

  defp extract_no_effective_change_handler(args) do
    case Keyword.pop(args, :on_no_effective_changes, :error) do
      {handler, args} when handler in [:error] -> {:ok, handler, args}
      {invalid, _} -> {:error, "invalid :on_no_effective_changes value: #{inspect(invalid)}"}
    end
  end

  defp extract_speech_act(args) do
    {speech_act_args, args} = Keyword.pop(args, :speech_act)

    cond do
      match?(%SpeechAct{}, speech_act_args) && Changeset.empty?(args) ->
        {:ok, speech_act_args, args}

      speech_act_args && Changeset.empty?(args) ->
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
  def call(%__MODULE__{} = command, store, %Repository{} = repo) do
    parent_commit = Repository.head_id(repo)

    with {:ok, effective_changeset} <-
           command.speech_act
           |> EffectiveChangesetQuery.new!()
           |> EffectiveChangesetQuery.call(store, repo),
         {:ok, commit} <-
           build_commit(
             parent_commit,
             command.speech_act,
             effective_changeset,
             command.commit_attrs,
             command.on_no_effective_changes
           ),
         {:ok, update} <- Update.build(repo, commit),
         :ok <- Store.update(store, nil, update),
         {:ok, new_repo} <- Repository.set_head(repo, commit) do
      {:ok, new_repo, commit}
    end
  end

  defp build_commit(_, _, :no_effective_changes, _, :error) do
    {:error, :no_effective_changes}
  end

  defp build_commit(parent_commit, speech_act, changeset, commit_attrs, _) do
    commit_attrs
    |> Keyword.put(:speech_act, speech_act)
    |> Keyword.put(:changeset, changeset)
    |> Keyword.put(:parent, parent_commit)
    |> Keyword.put_new(:committer, Config.agent())
    |> Keyword.put_new(:time, DateTime.utc_now())
    |> Commit.new()
  end
end
