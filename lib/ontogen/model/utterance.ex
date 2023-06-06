defmodule Ontogen.Utterance do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Expression, InvalidUtteranceError}
  alias Ontogen.Utterance.Id
  alias RDF.{IRI, Graph}

  schema Og.Utterance < PROV.Activity do
    link insertion: Og.insertion(), type: Expression
    link deletion: Og.deletion(), type: Expression

    property ended_at: PROV.endedAtTime(), type: :date_time, required: true
    link speaker: Og.speaker(), type: Ontogen.Agent
    link data_source: Og.dataSource(), type: DCAT.Dataset, depth: 0
  end

  def new(args) do
    args =
      args
      |> Keyword.update(:insertion, nil, &normalize_expression/1)
      |> Keyword.update(:deletion, nil, &normalize_expression/1)

    with {:ok, utterance} <- build(RDF.bnode(:tmp), args),
         {:ok, id} <- Id.generate(utterance) do
      utterance
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  defp normalize_expression(nil), do: nil
  defp normalize_expression(%Expression{} = expression), do: expression
  defp normalize_expression(%IRI{} = id), do: id
  defp normalize_expression(statements), do: Expression.new!(statements)

  def validate(utterance) do
    with :ok <- check_statements_present(utterance.insertion, utterance.deletion) do
      Grax.validate(utterance)
    end
  end

  defp check_statements_present(nil, nil),
    do: {:error, InvalidUtteranceError.exception(reason: "no statements")}

  defp check_statements_present(_, _), do: :ok

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Utterance})
    }
  end
end
