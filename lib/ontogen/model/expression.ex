defmodule Ontogen.Expression do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias RTC.Compound
  alias RDF.Graph

  import Ontogen.IdUtils

  schema Og.Expression do
    field :statements
  end

  def new(statements) do
    if id = dataset_hash_iri(statements) do
      build(id,
        statements:
          Compound.new(statements, id,
            name: nil,
            assertion_mode: :unasserted
          )
      )
    else
      {:error, :no_statements}
    end
  end

  def new!(statements) do
    case new(statements) do
      {:ok, expression} -> expression
      {:error, error} -> raise error
    end
  end

  def on_load(%__MODULE__{} = expression, graph, _opts) do
    {
      :ok,
      %__MODULE__{
        expression
        | statements:
            graph
            |> Compound.from_rdf(expression.__id__)
            |> Compound.change_graph_name(nil)
      }
      |> Grax.delete_additional_predicates(RTC.elements())
    }
  end

  def on_to_rdf(%__MODULE__{__id__: id, statements: compound}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.add(Compound.to_rdf(compound, element_style: :elements))
      |> Graph.delete({id, RDF.type(), Og.Expression})
    }
  end

  def graph(%__MODULE__{statements: compound}) do
    Compound.graph(compound)
  end
end
