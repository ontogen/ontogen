defmodule Ontogen.TestNamespaces do
  @moduledoc """
  Test namespaces.
  """

  use RDF.Vocabulary.Namespace
  defvocab EX, base_iri: "http://example.com/", terms: [], strict: false
end
