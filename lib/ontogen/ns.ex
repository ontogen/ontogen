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

  @prefixes RDF.prefix_map(
              og: Ontogen.NS.Og,
              oga: Ontogen.NS.OgA,
              mud: Mud,
              rtc: RTC,
              prov: PROV,
              dcat: DCAT,
              skos: SKOS,
              foaf: FOAF
            )

  def prefixes, do: @prefixes

  def prefixes(filter), do: RDF.PrefixMap.limit(@prefixes, filter)
end
