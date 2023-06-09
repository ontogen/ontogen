defmodule Ontogen.QueryUtils do
  alias RDF.NTriples

  def to_term(rdf_value) do
    NTriples.Encoder.term(rdf_value)
  end
end
