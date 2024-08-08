defmodule Ontogen.QueryUtils do
  @moduledoc false

  alias RDF.NTriples

  def graph_query do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
    |> Ontogen.Store.SPARQL.Operation.construct!()
  end

  def to_term(rdf_value) do
    NTriples.Encoder.term(rdf_value)
  end
end
