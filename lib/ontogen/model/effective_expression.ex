defmodule Ontogen.EffectiveExpression do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.Expression
  alias Ontogen.EffectiveExpression.Id

  alias RTC.Compound
  alias RDF.Graph

  schema Og.EffectiveExpression < Expression do
    link origin: Og.originExpression(), type: Expression, required: true
  end

  def new(%Expression{} = origin, statements) do
    origin_graph = graph(origin)
    graph = RDF.graph(statements)

    cond do
      Graph.equal?(origin_graph, graph) ->
        {:ok, origin}

      not Graph.include?(origin_graph, graph) ->
        {:error, :no_subset_of_origin}

      id = Id.generate(origin, graph) ->
        compound =
          Compound.new(graph, id,
            name: nil,
            assertion_mode: :unasserted
          )

        build(id, origin: origin, statements: compound)

      true ->
        {:error, :no_statements}
    end
  end

  def new!(origin, statements) do
    case new(origin, statements) do
      {:ok, effective_expression} -> effective_expression
      {:error, error} -> raise error
    end
  end

  defdelegate graph(expression), to: Expression
  defdelegate on_load(expression, graph, opts), to: Expression
  defdelegate on_to_rdf(expression, graph, opts), to: Expression
end
