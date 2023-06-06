defmodule Ontogen.Commands.FetchProvGraph do
  alias Ontogen.{Store, Repository, ProvGraph}
  alias RDF.Graph

  def call(store, repository) do
    prov_graph_id = Repository.prov_graph_id(repository)

    with {:ok, graph} <- Store.query(store, prov_graph_id, query(prov_graph_id)) do
      {:ok, graph |> Graph.add_prefixes(ProvGraph.prefixes())}
    end
  end

  defp query(_dataset_id) do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE     { ?s ?p ?o }
    """
  end
end
