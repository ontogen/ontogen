defmodule Ontogen.Commands.Commit do
  alias Ontogen.{
    Local,
    Store,
    Repository,
    Dataset,
    Commit,
    Changeset,
    InvalidCommitError
  }

  alias Ontogen.Commands.{CreateSpeechAct, FetchEffectiveChangeset}
  alias Ontogen.Commands.Commit.Update
  alias RDF.IRI

  def call(store, %Repository{} = repo, args) do
    parent_commit = parent_commit(repo.dataset)
    {no_effective_changes, args} = Keyword.pop(args, :no_effective_changes, :error)

    with {:ok, speech_act, args} <- extract_speech_act(args),
         {:ok, effective_changeset} <- FetchEffectiveChangeset.call(store, repo, speech_act),
         {:ok, commit} <-
           build_commit(
             parent_commit,
             speech_act,
             effective_changeset,
             args,
             no_effective_changes
           ),
         {:ok, update} <- Update.build(repo, commit),
         :ok <- Store.update(store, nil, update),
         {:ok, new_repo} <- Repository.set_head(repo, commit) do
      {:ok, new_repo, commit}
    end
  end

  defp parent_commit(%Dataset{head: nil}), do: nil
  defp parent_commit(%Dataset{head: %IRI{} = head}), do: head
  defp parent_commit(%Dataset{head: head}), do: head.__id__

  defp build_commit(_, _, :no_effective_changes, _, :error) do
    {:error, :no_effective_changes}
  end

  defp build_commit(_, _, :no_effective_changes, _, unknown) do
    raise ArgumentError, "unknown :no_effective_changes value: #{inspect(unknown)}"
  end

  defp build_commit(parent_commit, speech_act, changeset, args, _) do
    args
    |> Keyword.put(:speech_act, speech_act)
    |> Keyword.put(:changeset, changeset)
    |> Keyword.put(:parent, parent_commit)
    |> Keyword.put_new(:committer, Local.agent())
    |> Keyword.put_new(:time, DateTime.utc_now())
    |> Commit.new()
  end

  defp extract_speech_act(args) do
    {speech_act_args, args} = Keyword.pop(args, :speech_act)

    cond do
      speech_act_args && Changeset.empty?(args) ->
        with {:ok, speech_act} <- CreateSpeechAct.call(speech_act_args) do
          {:ok, speech_act, args}
        end

      speech_act_args ->
        {:error,
         InvalidCommitError.exception(reason: "speech acts are not allowed with other changes")}

      true ->
        CreateSpeechAct.extract(args)
    end
  end
end
