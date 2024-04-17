defmodule Ontogen.HistoryType.Formatter do
  @behaviour Ontogen.HistoryType

  alias Ontogen.HistoryType.Native
  alias Ontogen.HistoryType.Formatter.CommitFormatter

  @impl true
  def history(history_graph, subject_type, subject, opts \\ []) do
    {stream?, opts} = Keyword.pop(opts, :stream, false)

    with {:ok, commits} <- Native.history(history_graph, subject_type, subject, opts) do
      if stream? do
        {:ok, stream(commits, opts)}
      else
        {:ok, formatted(commits, opts)}
      end
    end
  end

  defp formatted(commits, opts) do
    commits
    |> stream(opts)
    |> Enum.into("")
  end

  defp stream(commits, opts) do
    {format, opts} = Keyword.pop(opts, :format, :default)

    Stream.map(commits, &format_commit(&1, format, opts))
  end

  defp format_commit(commit, format, opts) do
    CommitFormatter.format(commit, format, opts) <> "\n"
  end
end
