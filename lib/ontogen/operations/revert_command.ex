defmodule Ontogen.Operations.RevertCommand do
  use Ontogen.Command,
    params: [
      range: nil,
      commit_attrs: nil
    ]

  alias Ontogen.{Repository, Commit, IdUtils}

  alias Ontogen.Operations.{
    HistoryQuery,
    ChangesetQuery,
    CommitCommand
  }

  alias RDF.IRI

  api do
    def revert(args) do
      args
      |> RevertCommand.new()
      |> RevertCommand.__do_call__()
    end

    def revert!(args \\ []), do: bang!(&revert/1, [args])
  end

  def new(args) do
    with {:ok, range, commit_attrs} <- extract_range(args) do
      {:ok, %__MODULE__{range: range, commit_attrs: commit_attrs}}
    end
  end

  defp extract_range(args) do
    args =
      Keyword.new(args, fn
        {:to, value} -> {:base, value}
        unchanged -> unchanged
      end)

    {commit, args} = Keyword.pop(args, :commit)
    range_args_present? = Keyword.take(args, [:base, :target]) != []

    cond do
      commit && range_args_present? ->
        {:error, "mutual exclusive use of :commit and commit range specification"}

      commit ->
        with {:ok, range} <- commit_range(commit) do
          {:ok, range, args}
        end

      true ->
        Commit.Range.extract(args)
    end
  end

  defp commit_range(%Commit{} = commit), do: Commit.Range.new(commit.parent, commit)
  defp commit_range(%IRI{} = commit_id), do: Commit.Range.new(1, commit_id)
  defp commit_range(invalid), do: {:error, "invalid commit spec: #{inspect(invalid)}"}

  @impl true
  def call(%__MODULE__{} = command, store, %Repository{} = repo) do
    with {:ok, range} <- Commit.Range.fetch(command.range, store, repo),
         command = %__MODULE__{command | range: range},
         {:ok, history_query} <- ChangesetQuery.history_query(:dataset, range: range),
         {:ok, commits} <- HistoryQuery.call(history_query, store, repo),
         {:ok, changeset} <- changeset(commits),
         {:ok, commit_command} <-
           command
           |> commit_args(changeset, commits)
           |> CommitCommand.new() do
      CommitCommand.call(commit_command, store, repo)
    end
  end

  defp changeset([]), do: {:error, "no commits to revert"}

  defp changeset(commits) do
    {:ok,
     commits
     |> Commit.Changeset.merge()
     |> Commit.Changeset.invert()}
  end

  defp commit_args(%__MODULE__{} = command, changeset, commits) do
    commit_attrs = command.commit_attrs
    range = command.range

    commit_attrs
    |> Keyword.put(:reverted_base_commit, range.base)
    |> Keyword.put(:reverted_target_commit, range.target)
    |> Keyword.put_new(:message, default_message(commits))
    |> Keyword.put(:revert, changeset)
    |> Keyword.put(:on_no_effective_changes, :error)
  end

  def default_message(commits) do
    """
    Revert of commits:

    """ <>
      Enum.map_join(commits, &"- #{IdUtils.hash_from_iri(&1.__id__)}\n")
  end
end
