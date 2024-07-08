defmodule Ontogen.NS do
  @moduledoc """
  `RDF.Vocabulary.Namespace`s for the used vocabularies within Ontogen.
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
  The Ontogen store adapter vocabulary.
  """
  defvocab OgA,
    base_iri: "https://w3id.org/ontogen/store/adapter/",
    file: "ontogen_store_adapter.ttl",
    terms: [],
    strict: false

  @vocabdoc """
  The vocabulary for the precompiled Bog Turtle language.

  See <https://w3id.org/ontogen/spec>
  """
  defvocab Bog,
    base_iri: "https://w3id.org/bog#",
    file: "bog.ttl",
    case_violations: :fail

  @prefixes RDF.prefix_map(
              og: Ontogen.NS.Og,
              oga: Ontogen.NS.OgA,
              bog: Ontogen.NS.Bog,
              rtc: RTC,
              prov: PROV,
              dcat: DCAT,
              SKOS: SKOS,
              foaf: FOAF
            )

  def prefixes, do: @prefixes

  def prefixes(filter), do: RDF.PrefixMap.limit(@prefixes, filter)
end
