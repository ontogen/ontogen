defmodule Ontogen.Commands.Commit do
  alias Ontogen.{Local, Store, Repository, Dataset, Commit, InvalidCommitError}
  alias Ontogen.Commands.CreateUtterance
  alias Ontogen.Commands.Commit.Update
  alias RDF.IRI

  def call(store, %Repository{} = repo, args) do
    parent_commit = parent_commit(repo.dataset)

    with {:ok, commit, utterance} <- build_commit(parent_commit, args),
         {:ok, update} <- Update.build(repo, commit, utterance),
         {:ok, new_repo} <- Repository.set_head(repo, commit),
         :ok <- Store.update(store, nil, update) do
      {:ok, new_repo, commit}
    end
  end

  defp parent_commit(%Dataset{head: nil}), do: nil
  defp parent_commit(%Dataset{head: %IRI{} = head}), do: head
  defp parent_commit(%Dataset{head: head}), do: head.__id__

  defp build_commit(parent_commit, args) do
    {time, args} = Keyword.pop(args, :time, DateTime.utc_now())

    with {:ok, args, utterance} <- build_changes(args) do
      args
      |> Keyword.put(:parent, parent_commit)
      |> Keyword.put_new(:committer, Local.agent())
      |> Keyword.put_new(:ended_at, time)
      |> Commit.new()
      |> case do
        {:ok, commit} -> {:ok, commit, utterance}
        {:error, error} -> {:error, InvalidCommitError.exception(reason: error)}
      end
    end
  end

  defp build_changes(args) do
    {utterance, args} = Keyword.pop(args, :utter)
    {insertion, args} = Keyword.pop(args, :insert)
    {deletion, args} = Keyword.pop(args, :delete)

    do_build_changes(args, utterance, insertion, deletion)
  end

  defp do_build_changes(args, nil, insertion, deletion) do
    {
      :ok,
      args
      |> Keyword.put(:insertion, insertion)
      |> Keyword.put(:deletion, deletion),
      nil
    }
  end

  defp do_build_changes(args, utterance_args, nil, nil) do
    with {:ok, utterance} <- CreateUtterance.call(utterance_args) do
      {
        :ok,
        args
        |> Keyword.put(:insertion, utterance.insertion)
        |> Keyword.put(:deletion, utterance.deletion),
        utterance
      }
    end
  end

  defp do_build_changes(_, _, _, _) do
    {:error,
     InvalidCommitError.exception(reason: "utterances are not allowed with other changes")}
  end
end
