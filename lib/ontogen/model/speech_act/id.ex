defmodule Ontogen.SpeechAct.Id do
  import Ontogen.IdUtils

  alias Ontogen.SpeechAct

  def generate(%SpeechAct{} = speech_act) do
    content_hash_iri(:speech_act, &content/1, [speech_act])
  end

  def content(speech_act) do
    [
      if(speech_act.insert, do: "insert #{to_hash(speech_act.insert)}"),
      if(speech_act.delete, do: "delete #{to_hash(speech_act.delete)}"),
      if(speech_act.update, do: "update #{to_hash(speech_act.update)}"),
      if(speech_act.replace, do: "replace #{to_hash(speech_act.replace)}"),
      "context <#{to_id(SpeechAct.origin(speech_act))}> #{to_timestamp(speech_act.time)}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end
