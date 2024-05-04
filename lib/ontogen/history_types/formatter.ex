defmodule Ontogen.HistoryType.Formatter do
  @behaviour Ontogen.HistoryType

  alias Ontogen.HistoryType.Native
  alias Ontogen.Commit

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
    change_formats = Keyword.get(opts, :changes, []) |> List.wrap()

    splitter =
      if Commit.Formatter.one_line_format?(format) and Enum.empty?(change_formats) do
        "\n"
      else
        "\n\n"
      end

    commits
    |> Stream.map(&Commit.Formatter.format(&1, format, opts))
    |> Stream.intersperse(splitter)
  end
end
