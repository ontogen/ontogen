defmodule Ontogen.HistoryType.Formatter.ChangesetFormatter do
  alias Ontogen.{Changeset, Commit, SpeechAct}
  alias RDF.{Graph, Description}
  alias IO.ANSI

  import Ontogen.Utils

  # ATTENTION: The order of this list is relevant! Since Optimus, the command-line
  # parser used in the CLI, unfortunately doesn't keep the order of the options,
  # we show multiple selected format in the order defined by this list.
  @formats ~w[stat resource_only short_stat]a
  def formats, do: @formats

  def format(changeset, format, opts \\ [])

  def format(%Commit{} = commit, format, opts) do
    commit
    |> Commit.Changeset.new!()
    |> format(format, opts)
  end

  def format(%SpeechAct{} = speech_act, format, opts) do
    speech_act
    |> SpeechAct.Changeset.new!()
    |> format(format, opts)
  end

  def format(changeset, format, opts) do
    changeset
    |> do_format(format, opts)
    |> IO.iodata_to_binary()
  end

  defp do_format({insertions, deletions, overwrites, changed_resources}, :short_stat, _opts) do
    insertions_count = Graph.triple_count(insertions)
    deletions_count = Graph.triple_count(deletions)
    overwrites_count = Graph.triple_count(overwrites)

    [
      " #{Enum.count(changed_resources)} resources changed",
      if(insertions_count > 0, do: "#{insertions_count} insertions(+)"),
      if(deletions_count > 0, do: "#{deletions_count} deletions(-)"),
      if(overwrites_count > 0, do: "#{overwrites_count} overwrites(~)")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.intersperse(", ")
  end

  defp do_format(changeset, :short_stat, opts) do
    insertions = Changeset.Helper.inserts(changeset)
    deletions = Changeset.Helper.deletes(changeset)
    overwrites = Changeset.Helper.overwrites(changeset)
    changed_resources = changed_resources({insertions, deletions, overwrites})

    do_format({insertions, deletions, overwrites, changed_resources}, :short_stat, opts)
  end

  defp do_format(changeset, :resource_only, _opts) do
    changeset
    |> changed_resources()
    |> Enum.map(&to_string/1)
    |> Enum.sort()
    |> Enum.intersperse("\n")
  end

  defp do_format(changeset, :stat, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())
    insertions = Changeset.Helper.inserts(changeset)
    deletions = Changeset.Helper.deletes(changeset)
    overwrites = Changeset.Helper.overwrites(changeset)

    max_change_length =
      (Enum.count(insertions) + Enum.count(deletions) + Enum.count(overwrites))
      |> Integer.to_string()
      |> String.length()

    changed_resources =
      changed_resources({insertions, deletions, overwrites})
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    longest_resource = changed_resources |> Enum.map(&String.length/1) |> Enum.max()
    max_resource_column_length = max_resource_column_length(max_change_length)

    {resource_column, truncate?} =
      if longest_resource > max_resource_column_length do
        {max_resource_column_length, true}
      else
        {longest_resource, false}
      end

    max_change_stats_length = terminal_width() - resource_column - max_change_length - 5

    [
      Enum.map(changed_resources, fn resource ->
        resource_insertions = insertions |> Graph.description(resource) |> Description.count()
        resource_deletions = deletions |> Graph.description(resource) |> Description.count()
        resource_overwrites = overwrites |> Graph.description(resource) |> Description.count()

        [resource_insertions_display, resource_deletions_display, resource_overwrites_display] =
          display_count(
            [resource_insertions, resource_deletions, resource_overwrites],
            max_change_stats_length
          )

        [
          " ",
          if(truncate?, do: truncate(resource, resource_column), else: resource)
          |> String.pad_trailing(resource_column),
          " | ",
          to_string(resource_insertions + resource_deletions + resource_overwrites)
          |> String.pad_leading(max_change_length),
          " ",
          ANSI.format([:green, String.duplicate("+", resource_insertions_display)], colorize),
          ANSI.format([:red, String.duplicate("-", resource_deletions_display)], colorize),
          ANSI.format([:light_red, String.duplicate("~", resource_overwrites_display)], colorize),
          "\n"
        ]
      end),
      do_format({insertions, deletions, overwrites, changed_resources}, :short_stat, opts)
    ]
  end

  defp do_format(_, invalid, _) do
    raise ArgumentError,
          "invalid change format: #{inspect(invalid)}. Possible formats: #{Enum.join(@formats, ", ")}"
  end

  defp changed_resources({insertions, deletions, overwrites}) do
    insertions
    |> Graph.subjects()
    |> MapSet.new()
    |> MapSet.union(deletions |> Graph.subjects() |> MapSet.new())
    |> MapSet.union(overwrites |> Graph.subjects() |> MapSet.new())
  end

  defp changed_resources(changeset) do
    {
      Changeset.Helper.inserts(changeset),
      Changeset.Helper.deletes(changeset),
      Changeset.Helper.overwrites(changeset)
    }
    |> changed_resources()
  end

  defp display_count(elements, max_change_length) do
    {elements, _remaining} =
      Enum.reduce(elements, {[], max_change_length}, fn count, {elements, remaining} ->
        if count > remaining do
          {[remaining | elements], 0}
        else
          {[count | elements], remaining - count}
        end
      end)

    Enum.reverse(elements)
  end

  defp max_resource_column_length(reserved), do: div((terminal_width() - reserved) * 95, 100)
end
