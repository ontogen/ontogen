defmodule Ontogen.History do
  use Grax.Schema
  use Mud.Referencable

  alias Ontogen.NS.Og
  alias RDF.PrefixMap

  @prefixes RDF.standard_prefixes() |> PrefixMap.merge!(rtc: RTC, og: Og)

  schema Og.History < DCATR.SystemGraph do
  end

  def prefixes, do: @prefixes
end
