defmodule Ontogen.EffectiveExpression.Id do
  import Ontogen.IdUtils

  def generate(origin, statements) do
    with {:ok, dataset_hash} <- dataset_hash(statements) do
      {:ok, content_hash_iri(:effective_expression, &content/2, [origin, dataset_hash])}
    end
  end

  def content(origin, dataset_hash) do
    [
      "statements #{dataset_hash}",
      "origin #{origin |> to_id() |> hash_from_iri()}"
    ]
    |> Enum.join("\n")
  end
end
