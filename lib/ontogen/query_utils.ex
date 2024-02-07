defmodule Ontogen.QueryUtils do
  alias RDF.NTriples

  def graph_query do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end

  def to_term(rdf_value) do
    NTriples.Encoder.term(rdf_value)
  end
end
