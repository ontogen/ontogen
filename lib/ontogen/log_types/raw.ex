defmodule Ontogen.LogType.Raw do
  @behaviour Ontogen.LogType

  alias Ontogen.NS.Og
  alias RDF.{Graph, PrefixMap}

  @prefixes RDF.prefixes(og: Og, rtc: RTC)
            |> PrefixMap.merge!(RDF.standard_prefixes())

  @impl true
  def log(history_graph, {:dataset, _}, _opts \\ []) do
    {:ok, Graph.add_prefixes(history_graph, @prefixes)}
  end
end
