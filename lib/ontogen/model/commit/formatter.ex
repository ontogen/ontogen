defmodule Ontogen.Commit.Formatter do
  @moduledoc false

  alias Ontogen.{Commit, SpeechAct}
  alias IO.ANSI

  import Ontogen.{FormatterHelper, IdUtils, Utils}

  @speech_act_formats %{
    speech_act: :full,
    raw_speech_act: :raw
  }

  @one_line_formats ~w[default oneline]a
  @multi_line_formats ~w[short medium full speech_act raw speech_act_raw]a
  @formats @one_line_formats ++ @multi_line_formats
  def formats, do: @formats

  def one_line_format?(format) when format in @one_line_formats, do: true
  def one_line_format?(_), do: false

  def format(%Commit{} = commit, format, opts \\ []) do
    if speech_act_format = @speech_act_formats[format] do
      if Commit.revert?(commit) do
        "Revert without speech act"
      else
        SpeechAct.Formatter.format(commit.speech_act, speech_act_format, opts)
      end
    else
      change_formats = Keyword.get(opts, :changes, []) |> List.wrap()

      [
        do_format(commit, format, opts),
        if Enum.empty?(change_formats) do
          []
        else
          [
            if(one_line_format?(format), do: "\n", else: "\n\n")
            | changes(commit, change_formats, opts)
          ]
        end
      ]
      |> IO.iodata_to_binary()
    end
  end

  defp do_format(commit, :default, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())
    hash_format = Keyword.get(opts, :hash_format, :short)

    [
      ANSI.format([:yellow, hash(commit, hash_format)], colorize),
      " - ",
      if(Commit.revert?(commit),
        do: ANSI.format([:italic, summary(commit.message)], colorize),
        else: summary(commit.message)
      ),
      " ",
      ANSI.format([:green, "(", human_relative_time(commit.time), ")"], colorize),
      " ",
      ANSI.format([:bright, :blue, "<", agent(commit.committer, false), ">"], colorize)
    ]
  end

  defp do_format(commit, :oneline, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())
    hash_format = Keyword.get(opts, :hash_format, :full)

    [
      ANSI.format([:yellow, hash(commit, hash_format)], colorize),
      " ",
      if(Commit.revert?(commit),
        do: ANSI.format([:italic, summary(commit.message)], colorize),
        else: summary(commit.message)
      )
    ]
  end

  defp do_format(commit, :short, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())
    hash_format = Keyword.get(opts, :hash_format, :full)

    [
      ANSI.format([:yellow, "commit ", hash(commit, hash_format)], colorize),
      "\n",
      if(Commit.revert?(commit),
        do: revert_fields(commit),
        else: author_or_source(commit.speech_act)
      ),
      "\n",
      summary(commit.message)
    ]
  end

  defp do_format(commit, :medium, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())
    hash_format = Keyword.get(opts, :hash_format, :full)

    [
      ANSI.format([:yellow, "commit ", hash(commit, hash_format)], colorize),
      "\n",
      if Commit.revert?(commit) do
        [
          revert_fields(commit),
          ["Date:         ", time(commit.time), "\n"]
        ]
      else
        [
          if(commit.speech_act.data_source,
            do: ["Source: <", to_id(commit.speech_act.data_source), ">\n"],
            else: []
          ),
          if(commit.speech_act.speaker,
            do: ["Author: ", agent(commit.speech_act.speaker), "\n"],
            else: []
          ),
          ["Date:   ", time(commit.speech_act.time), "\n"]
        ]
      end,
      "\n",
      commit.message
    ]
  end

  defp do_format(commit, :full, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())
    hash_format = Keyword.get(opts, :hash_format, :full)
    padding = if Commit.revert?(commit), do: 14, else: 12

    [
      ANSI.format([:yellow, "commit ", hash(commit, hash_format)], colorize),
      "\n",
      if Commit.revert?(commit) do
        revert_fields(commit)
      else
        [
          [
            "Source:     ",
            if(commit.speech_act.data_source,
              do: ["<", to_id(commit.speech_act.data_source), ">"],
              else: "-"
            ),
            "\n"
          ],
          [
            "Author:     ",
            if(commit.speech_act.speaker, do: agent(commit.speech_act.speaker), else: "-"),
            "\n"
          ],
          ["AuthorDate: ", time(commit.speech_act.time), "\n"]
        ]
      end,
      [String.pad_trailing("Commit:", padding), agent(commit.committer), "\n"],
      [String.pad_trailing("CommitDate:", padding), time(commit.time), "\n"],
      "\n",
      commit.message
    ]
  end

  defp do_format(commit, :raw, opts) do
    colorize = Keyword.get(opts, :color, ANSI.enabled?())

    [
      ANSI.format([:yellow, "commit ", hash(commit, :full)], colorize),
      "\n",
      Commit.Id.content(commit)
    ]
  end

  defp do_format(_, invalid, _opts) do
    raise ArgumentError,
          "invalid format: #{inspect(invalid)}. Possible formats: #{Enum.join(@formats, ", ")}"
  end

  defp summary(message), do: first_line(message)

  defp revert_fields(commit) do
    [
      "RevertBase:   ",
      hash_from_iri(commit.reverted_base_commit),
      "\n",
      "RevertTarget: ",
      hash_from_iri(commit.reverted_target_commit),
      "\n"
    ]
  end
end
