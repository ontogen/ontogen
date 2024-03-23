defmodule Ontogen.Operations.RevertCommand do
  use Ontogen.Command,
    params: [
      history_query: nil,
      commit_attrs: nil
    ]

  alias Ontogen.{Commit, Repository, IdUtils}

  alias Ontogen.Operations.{
    HistoryQuery,
    ChangesetQuery,
    CommitCommand
  }

  api do
    def revert(args) do
      args
      |> RevertCommand.new()
      |> RevertCommand.__do_call__()
    end
  end

  def new(args) do
    with {:ok, range, commit_attrs} <- extract_range(args),
         {:ok, history_query} <- ChangesetQuery.history_query(:dataset, range: range) do
      {:ok, %__MODULE__{history_query: history_query, commit_attrs: commit_attrs}}
    end
  end

  defp extract_range(args) do
    {commit, args} = Keyword.pop(args, :commit)

    args
    |> Keyword.new(fn
      {:to, value} -> {:base, value}
      unchanged -> unchanged
    end)
    |> Commit.Range.extract()
    |> case do
      {:ok, %Commit.Range{base: nil, target: :head}, remaining_args} ->
        with {:ok, range} <- commit_range(commit) do
          {:ok, range, remaining_args}
        end

      {:ok, %Commit.Range{}, _} when not is_nil(commit) ->
        {:error, "mutual exclusive use of :commit and commit range specification"}

      ok_or_error ->
        ok_or_error
    end
  end

  defp commit_range(%Commit{} = commit), do: Commit.Range.new(commit.parent, commit)
  defp commit_range(nil), do: {:error, "no commits to revert specified"}
  defp commit_range(invalid), do: {:error, "invalid commit spec: #{inspect(invalid)}"}

  @impl true
  def call(%__MODULE__{} = command, store, %Repository{} = repo) do
    with {:ok, commits} <- HistoryQuery.call(command.history_query, store, repo),
         {:ok, changeset} <- changeset(commits),
         {:ok, commit_command} <-
           command
           |> commit_args(changeset, commits, Repository.head_id(repo))
           |> CommitCommand.new() do
      CommitCommand.call(commit_command, store, repo)
    end
  end

  defp changeset([]), do: {:error, "no commits to revert"}

  defp changeset(history) do
    {:ok,
     history
     |> Commit.Changeset.merge()
     |> Commit.Changeset.invert()}
  end

  defp commit_args(%__MODULE__{} = command, changeset, commits, head) do
    commit_attrs = command.commit_attrs
    range = command.history_query.range

    cond do
      range.target in [:head, head] ->
        Keyword.put(commit_attrs, :reverted_base_commit, range.base)

      length(commits) == 1 ->
        Keyword.put(commit_attrs, :reverted_target_commit, range.target)

      true ->
        commit_attrs
        |> Keyword.put(:reverted_base_commit, range.base)
        |> Keyword.put(:reverted_target_commit, range.target)
    end
    |> Keyword.put_new(:message, default_message(commits))
    |> Keyword.put(:revert, changeset)
    |> Keyword.put(:on_no_effective_changes, :error)
  end

  defp default_message(commits) do
    """
    Revert of commits:

    """ <>
      Enum.map_join(commits, &"- #{IdUtils.hash_from_iri(&1.__id__)}\n")
  end
end
