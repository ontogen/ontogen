defmodule Ontogen.HistoryType.Raw do
  @behaviour Ontogen.HistoryType

  alias Ontogen.NS.Og
  alias RDF.{Graph, PrefixMap}

  @prefixes RDF.prefixes(og: Og, rtc: RTC)
            |> PrefixMap.merge!(RDF.standard_prefixes())

  @impl true
  def history(history_graph, _, _, _opts \\ []) do
    {:ok, Graph.add_prefixes(history_graph, @prefixes)}
  end
end
