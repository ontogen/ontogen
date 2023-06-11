defmodule Ontogen.Utterance.Id do
  import Ontogen.IdUtils

  alias Ontogen.Utterance

  def generate(%Utterance{} = utterance) do
    if origin = determine_origin(utterance) do
      {:ok,
       content_hash_iri(:utterance, &content/4, [
         utterance.insertion,
         utterance.deletion,
         origin,
         utterance.time
       ])}
    else
      {:error, error("origin missing", Utterance)}
    end
  end

  def content(insertion, deletion, origin, time) do
    [
      if(insertion, do: "insertion #{to_hash(insertion)}"),
      if(deletion, do: "deletion #{to_hash(deletion)}"),
      "context <#{to_id(origin)}> #{to_timestamp(time)}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp determine_origin(utterance) do
    utterance.speaker || utterance.data_source ||
      utterance.was_associated_with |> List.wrap() |> List.first()
  end
end
