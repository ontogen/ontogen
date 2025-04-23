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

  @prefixes RDF.prefix_map(
              og: Ontogen.NS.Og,
              gno: Gno,
              gnoa: Gno.NS.GnoA,
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
