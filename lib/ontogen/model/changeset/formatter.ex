defmodule Ontogen.Changeset.Formatter do
  @moduledoc false

  alias Ontogen.{Commit, SpeechAct}
  alias Gno.{Changeset, EffectiveChangeset}
  alias RDF.Graph

  import Gno.Utils

  # ATTENTION: The order of this list is relevant! Since Optimus, the command-line
  # parser used in the CLI, unfortunately doesn't keep the order of the options,
  # we show multiple selected format in the order defined by this list.
  @formats ~w[combined_changes speech_changes]a ++ Gno.Changeset.Formatter.formats()
  def formats, do: @formats

  def format(changeset, format, opts \\ [])

  def format(%Commit{speech_act: nil}, :speech_changes, _opts),
    do: "# Revert without speech act"

  def format(%Commit{} = commit, :speech_changes, opts),
    do: format(commit.speech_act, :changes, opts)

  def format(invalid, :speech_changes, _opts),
    do: raise(ArgumentError, "Invalid struct for speech_changes format: #{inspect(invalid)}")

  def format(%Commit{speech_act: nil} = commit, :combined_changes, opts),
    do: format(commit, :changes, opts)

  def format(%Commit{} = commit, :combined_changes, opts),
    do: format_combined_changes(commit, opts)

  def format(invalid, :combined_changes, _opts),
    do: raise(ArgumentError, "Invalid struct for combined_changes format: #{inspect(invalid)}")

  def format(%Commit{} = commit, format, opts) do
    commit
    |> EffectiveChangeset.new!()
    |> format(format, opts)
  end

  def format(%SpeechAct{} = speech_act, format, opts) do
    speech_act
    |> Changeset.new!()
    |> format(format, opts)
  end

  def format(changeset, format, opts) do
    Gno.Changeset.Formatter.format(changeset, format, opts)
  end

  defp format_combined_changes(commit, opts) do
    colorize = Keyword.get(opts, :color, Gno.ansi_enabled?())
    committed_changes = EffectiveChangeset.new!(commit)
    speech_act_changes = Changeset.new!(commit.speech_act)

    committed_changes
    |> Changeset.Helper.merged_graph()
    |> Graph.add(Changeset.Helper.merged_graph(speech_act_changes))
    |> Graph.add(Keyword.get(opts, :context_data, Graph.new()))
    |> Gno.Changeset.Formatter.diff(
      combined_diff_prefixer(committed_changes, speech_act_changes, colorize),
      colorize
    )
  end

  defp combined_diff_prefixer(commit, speech_act, colorize) do
    none = if colorize, do: [IO.ANSI.reset(), "   "], else: "   "

    fn
      :description, subject, _ ->
        if Changeset.Helper.includes?(commit, subject) or
             not Changeset.Helper.includes?(speech_act, subject) do
          none
        else
          "#  "
          |> colorize_ineffective(colorize)
          |> clean_ansi(colorize)
        end

      :triple, triple, _ ->
        cond do
          action = Changeset.Helper.action(commit, triple) ->
            [" " | Gno.Changeset.Formatter.change_prefix(action, colorize)]
            |> clean_ansi(colorize)

          action = Changeset.Helper.action(speech_act, triple) ->
            ["#", Gno.Changeset.Formatter.change_prefix(action, colorize)]
            |> colorize_ineffective(colorize)
            |> clean_ansi(colorize)

          true ->
            none
        end

      _, _, _ ->
        none
    end
  end

  defp colorize_ineffective(prefix, true),
    do: [IO.ANSI.white(), IO.ANSI.faint(), prefix, IO.ANSI.crossed_out()]

  defp colorize_ineffective(prefix, _), do: prefix
end
