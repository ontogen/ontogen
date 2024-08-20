defmodule Ontogen.SpeechAct.Formatter do
  @moduledoc false

  alias Ontogen.SpeechAct
  alias IO.ANSI

  import Ontogen.{FormatterHelper, IdUtils}

  @formats ~w[full raw]a
  def formats, do: @formats

  def format(%SpeechAct{} = speech_act, format, opts \\ []) do
    change_formats = Keyword.get(opts, :changes, []) |> List.wrap()

    [
      do_format(speech_act, format, opts),
      if Enum.empty?(change_formats) do
        []
      else
        ["\n\n" | changes(speech_act, change_formats, opts)]
      end
    ]
    |> IO.iodata_to_binary()
  end

  defp do_format(speech_act, :full, opts) do
    colorize = Keyword.get(opts, :color, Ontogen.ansi_enabled?())
    hash_format = Keyword.get(opts, :hash_format, :full)

    [
      ANSI.format([:yellow, "speech_act ", hash(speech_act, hash_format)], colorize),
      "\n",
      [
        "Source: ",
        if(speech_act.data_source,
          do: ["<", to_id(speech_act.data_source), ">"],
          else: "-"
        ),
        "\n"
      ],
      [
        "Author: ",
        if(speech_act.speaker, do: agent(speech_act.speaker), else: "-"),
        "\n"
      ],
      ["Date:   ", time(speech_act.time)]
    ]
  end

  defp do_format(speech_act, :raw, opts) do
    colorize = Keyword.get(opts, :color, Ontogen.ansi_enabled?())

    [
      ANSI.format([:yellow, "speech_act ", hash(speech_act, :full)], colorize),
      "\n",
      SpeechAct.Id.content(speech_act)
    ]
  end

  defp do_format(_, invalid, _opts) do
    raise ArgumentError,
          "invalid format: #{inspect(invalid)}. Possible formats: #{Enum.join(@formats, ", ")}"
  end
end
