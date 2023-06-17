defmodule Ontogen.Utterance.Id do
  import Ontogen.IdUtils

  alias Ontogen.Utterance

  def generate(%Utterance{} = utterance) do
    if origin = determine_origin(utterance) do
      {:ok, content_hash_iri(:utterance, &content/2, [utterance, origin])}
    else
      {:error, error("origin missing", Utterance)}
    end
  end

  def content(utterance, origin) do
    [
      if(utterance.insertion, do: "insertion #{to_hash(utterance.insertion)}"),
      if(utterance.deletion, do: "deletion #{to_hash(utterance.deletion)}"),
      if(utterance.update, do: "deletion #{to_hash(utterance.update)}"),
      if(utterance.replacement, do: "deletion #{to_hash(utterance.replacement)}"),
      "context <#{to_id(origin)}> #{to_timestamp(utterance.time)}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp determine_origin(utterance) do
    utterance.speaker || utterance.data_source ||
      utterance.was_associated_with |> List.wrap() |> List.first()
  end
end
