defmodule Ontogen.Expression do
  use Grax.Schema
  use RDF

  alias Ontogen.NS.Og
  alias RTC.Compound
  alias RDF.Graph

  schema Og.Expression do
    field :statements
  end

  def new(statements) do
    with {:ok, id} <- hash_iri(statements) do
      build(id,
        statements:
          Compound.new(statements, id,
            name: nil,
            assertion_mode: :unasserted
          )
      )
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

  def hash_iri(statements) do
    with {:ok, hash} <- hash(statements) do
      {:ok, ~i<urn:hash::sha256:#{hash}>}
    end
  end

  def hash_iri!(statements) do
    case hash_iri(statements) do
      {:ok, id} -> id
      {:error, error} -> raise error
    end
  end

  def hash(statements) do
    graph = RDF.graph(statements)

    if Graph.empty?(graph) do
      {:error, :no_statements}
    else
      {:ok,
       :crypto.hash(:sha256, NQuads.write_string!(graph))
       |> Base.encode16(case: :lower)}
    end
  end
end
