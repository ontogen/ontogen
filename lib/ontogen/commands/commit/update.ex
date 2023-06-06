defmodule Ontogen.Commands.Commit.Update do
  alias Ontogen.{Expression, Repository}
  alias Ontogen.NS.Og
  alias RDF.NTriples

  def build(repo, commit, utterance) do
    {:ok,
     """
     PREFIX og: <#{Og.__base_iri__()}>
     DELETE DATA {
       #{head(repo, commit.parent)}
       #{dataset_changes(repo, commit.deletion)}
     } ;
     INSERT DATA {
       #{head(repo, commit.__id__)}
       #{dataset_changes(repo, commit.insertion)}
       #{provenance(repo, commit)}
       #{provenance(repo, utterance)}
     }
     """}
  end

  defp head(_, nil), do: ""

  defp head(repo, head) do
    "GRAPH <#{Repository.graph_id(repo)}> { <#{Repository.dataset_graph_id(repo)}> og:head <#{head}> }"
  end

  defp dataset_changes(_, nil), do: ""

  defp dataset_changes(repo, expression) do
    data =
      expression
      |> Expression.graph()
      |> triples()

    "GRAPH <#{Repository.dataset_graph_id(repo)}> { #{data} }"
  end

  defp provenance(_, nil), do: ""

  defp provenance(repo, element) do
    "GRAPH <#{Repository.prov_graph_id(repo)}> { #{element |> Grax.to_rdf!() |> triples()} }"
  end

  defp triples(data), do: NTriples.write_string!(data)
end
