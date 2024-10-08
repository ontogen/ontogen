defmodule Ontogen.Proposition do
  use Grax.Schema

  alias Ontogen.NS.Og

  alias RTC.Compound
  alias RDF.Graph

  import Ontogen.Utils, only: [bang!: 2]
  import Ontogen.IdUtils

  schema Og.Proposition do
    field :statements
  end

  def new(statements) do
    with {:ok, id} <- dataset_hash_iri(statements) do
      build(id,
        statements:
          Compound.new(statements, id,
            name: nil,
            assertion_mode: :unasserted
          )
      )
    end
  end

  def new!(statements \\ []), do: bang!(&new/1, [statements])

  def on_load(%{} = proposition, graph, _opts) do
    {
      :ok,
      %{
        proposition
        | statements:
            graph
            |> Graph.take([proposition.__id__], [RTC.elements()])
            |> Compound.from_rdf(proposition.__id__)
            |> Compound.change_graph_name(nil)
      }
      |> Grax.delete_additional_predicates(RTC.elements())
    }
  end

  def on_to_rdf(%{__id__: id, statements: compound}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.add(Compound.to_rdf(compound, element_style: :elements))
      |> Graph.delete({id, RDF.type(), Og.Proposition})
    }
  end

  def graph(nil), do: nil
  def graph(%__MODULE__{statements: compound}), do: Compound.graph(compound)
end
