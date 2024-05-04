defmodule Ontogen.Commit.Formatter do
  alias Ontogen.{Commit, SpeechAct, Changeset, Agent}
  alias RDF.IRI
  alias IO.ANSI

  import Ontogen.{IdUtils, Utils}

  @one_line_formats ~w[default oneline]a
  @multi_line_formats ~w[short medium full raw]a
  @formats @one_line_formats ++ @multi_line_formats

  @hash_formats ~w[short full iri]a

  def formats, do: @formats

  def one_line_format?(format) when format in @one_line_formats, do: true
  def one_line_format?(_), do: false

  def hash_formats, do: @hash_formats

  def format(%Commit{} = commit, format, opts \\ []) do
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

  defp changes(commit, change_formats, opts) do
    change_formats
    |> Enum.map(&Changeset.Formatter.format(commit, &1, opts))
    |> Enum.intersperse("\n\n")
  end

  defp hash(%Commit{__id__: iri}, format), do: hash(iri, format)
  defp hash(%IRI{} = iri, :iri), do: to_string(iri)
  defp hash(%IRI{} = iri, :full), do: hash_from_iri(iri)
  defp hash(%IRI{} = iri, :short), do: short_hash_from_iri(iri)

  defp summary(message), do: first_line(message)

  defp agent(agent, email_with_brackets \\ true)
  defp agent(%IRI{} = iri, false), do: to_string(iri)
  defp agent(%IRI{} = iri, true), do: ["<", to_string(iri), ">"]

  defp agent(%Agent{name: nil, email: nil} = agent, false),
    do: ["??? ", to_string(agent.__id__)]

  defp agent(%Agent{name: nil, email: nil} = agent, true),
    do: ["??? <", to_string(agent.__id__), ">"]

  defp agent(%Agent{} = agent, false),
    do: [agent.name || "???", " ", Agent.email(agent) || "???"]

  defp agent(%Agent{} = agent, true),
    do: [agent.name || "???", " <", Agent.email(agent) || "???", ">"]

  defp author_or_source(%SpeechAct{speaker: speaker}) when not is_nil(speaker),
    do: ["Author: ", agent(speaker), "\n"]

  defp author_or_source(%SpeechAct{data_source: source}) when not is_nil(source),
    do: ["Source: <", to_id(source), ">\n"]

  defp revert_fields(commit) do
    reverted_base =
      if commit.reverted_base_commit do
        ["RevertBase:   ", hash_from_iri(commit.reverted_base_commit), "\n"]
      end

    reverted_target =
      if commit.reverted_target_commit do
        ["RevertTarget: ", hash_from_iri(commit.reverted_target_commit), "\n"]
      end

    if reverted_base && reverted_target do
      [reverted_base, reverted_target]
    else
      reverted_base || reverted_target
    end
  end

  defp time(datetime), do: Calendar.strftime(datetime, "%a %b %d %X %Y %z")
end
