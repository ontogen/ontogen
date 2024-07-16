defmodule Ontogen.ProvGraph do
  use Grax.Schema
  use Ontogen.Bog.Referencable

  alias Ontogen.NS.Og
  alias RDF.PrefixMap

  @prefixes RDF.standard_prefixes() |> PrefixMap.merge!(rtc: RTC, og: Og)

  schema Og.ProvGraph do
  end

  def prefixes, do: @prefixes
end
