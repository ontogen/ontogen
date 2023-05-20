defmodule Ontogen.NS do
  @moduledoc """
  `RDF.Vocabulary.Namespace`s for the used vocabularies.
  """

  use RDF.Vocabulary.Namespace

  @vocabdoc """
  The Ontogen vocabulary.

  See <https://w3id.org/ontogen/spec>
  """
  defvocab Og,
    base_iri: "https://w3id.org/ontogen#",
    file: "ontogen.ttl",
    case_violations: :fail

  @vocabdoc """
  The Ontogen config vocabulary.
  """
  defvocab Ogc,
    base_iri: "https://w3id.org/ontogen/config#",
    file: "ontogen_config.ttl",
    case_violations: :fail
end
