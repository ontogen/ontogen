defmodule Ontogen.Commands.Commit do
  alias Ontogen.{
    Local,
    Store,
    Repository,
    Dataset,
    Commit,
    Changeset,
    InvalidChangesetError,
    InvalidCommitError
  }

  alias Ontogen.Commands.{CreateUtterance, FetchEffectiveChangeset}
  alias Ontogen.Commands.Commit.Update
  alias RDF.IRI

  def call(store, %Repository{} = repo, args) do
    parent_commit = parent_commit(repo.dataset)

    with {:ok, changeset, utterance, args} <- extract_changes(args),
         {:ok, effective_changeset} <- FetchEffectiveChangeset.call(store, repo, changeset),
         {:ok, commit} <- build_commit(parent_commit, changeset, args),
         {:ok, effective_commit} <- Commit.effective(commit, effective_changeset),
         {:ok, update} <- Update.build(repo, effective_commit, utterance),
         :ok <- Store.update(store, nil, update),
         {:ok, new_repo} <- Repository.set_head(repo, effective_commit) do
      {:ok, new_repo, effective_commit, utterance}
    end
  end

  defp parent_commit(%Dataset{head: nil}), do: nil
  defp parent_commit(%Dataset{head: %IRI{} = head}), do: head
  defp parent_commit(%Dataset{head: head}), do: head.__id__

  defp build_commit(parent_commit, changeset, args) do
    args
    |> Keyword.put(:changeset, changeset)
    |> Keyword.put(:parent, parent_commit)
    |> Keyword.put_new(:committer, Local.agent())
    |> Keyword.put_new(:time, DateTime.utc_now())
    |> Commit.new()
  end

  defp extract_changes(args) do
    {utterance_args, args} = Keyword.pop(args, :utter)

    do_extract_changes(args, utterance_args, Changeset.extract(args))
  end

  defp do_extract_changes(_, nil, {:ok, changeset, args}), do: {:ok, changeset, nil, args}
  defp do_extract_changes(_, nil, error), do: error

  defp do_extract_changes(args, utterance_args, {:error, %InvalidChangesetError{reason: :empty}}) do
    with {:ok, utterance} <- CreateUtterance.call(utterance_args),
         {:ok, changeset} <- Changeset.new(utterance) do
      {:ok, changeset, utterance, args}
    end
  end

  defp do_extract_changes(_, _, _) do
    {:error,
     InvalidCommitError.exception(reason: "utterances are not allowed with other changes")}
  end
end
