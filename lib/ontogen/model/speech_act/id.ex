defmodule Ontogen.SpeechAct.Id do
  import Ontogen.IdUtils

  alias Ontogen.SpeechAct

  def generate(%SpeechAct{} = speech_act) do
    content_hash_iri(:speech_act, &content/1, [speech_act])
  end

  def content(speech_act) do
    [
      if(speech_act.add, do: "add #{to_hash(speech_act.add)}\n"),
      if(speech_act.update, do: "update #{to_hash(speech_act.update)}\n"),
      if(speech_act.replace, do: "replace #{to_hash(speech_act.replace)}\n"),
      if(speech_act.remove, do: "remove #{to_hash(speech_act.remove)}\n"),
      "context <#{to_id(SpeechAct.origin(speech_act))}> #{to_timestamp(speech_act.time)}\n"
    ]
    |> Enum.reject(&is_nil/1)
    |> IO.iodata_to_binary()
  end
end
