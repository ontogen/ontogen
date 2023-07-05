defmodule Ontogen.SpeechAct.Id do
  import Ontogen.IdUtils

  alias Ontogen.SpeechAct

  def generate(%SpeechAct{} = speech_act) do
    if origin = determine_origin(speech_act) do
      {:ok, content_hash_iri(:speech_act, &content/2, [speech_act, origin])}
    else
      {:error, error("origin missing", SpeechAct)}
    end
  end

  def content(speech_act, origin) do
    [
      if(speech_act.insertion, do: "insertion #{to_hash(speech_act.insertion)}"),
      if(speech_act.deletion, do: "deletion #{to_hash(speech_act.deletion)}"),
      if(speech_act.update, do: "deletion #{to_hash(speech_act.update)}"),
      if(speech_act.replacement, do: "deletion #{to_hash(speech_act.replacement)}"),
      "context <#{to_id(origin)}> #{to_timestamp(speech_act.time)}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp determine_origin(speech_act) do
    speech_act.speaker || speech_act.data_source ||
      speech_act.was_associated_with |> List.wrap() |> List.first()
  end
end
