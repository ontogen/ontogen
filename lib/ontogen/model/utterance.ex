defmodule Ontogen.Utterance do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.Expression
  alias RDF.{IRI, Graph}

  schema Og.Utterance < PROV.Activity do
    property ended_at: PROV.endedAtTime(), type: :date_time, required: true

    link insertion: Og.insertion(), type: Expression
    link deletion: Og.deletion(), type: Expression

    link data_source: Og.dataSource(), type: DCAT.Dataset, depth: 0
  end

  def new(args) do
    {id, args} = Keyword.pop(args, :id)

    args
    |> Keyword.update(:insertion, nil, &normalize_expression/1)
    |> Keyword.update(:deletion, nil, &normalize_expression/1)
    |> do_build(id)
    |> Grax.validate()
  end

  def new!(args) do
    case new(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  defp do_build(args, nil), do: build!(args)
  defp do_build(args, id), do: build!(id, args)

  defp normalize_expression(nil), do: nil
  defp normalize_expression(%Expression{} = expression), do: expression
  defp normalize_expression(%IRI{} = id), do: id
  defp normalize_expression(statements), do: Expression.new!(statements)

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Utterance})
    }
  end
end
