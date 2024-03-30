defmodule Ontogen.Operations.CommitCommand.Update do
  @moduledoc false

  alias Ontogen.{Proposition, Repository}
  alias RDF.{NTriples, PrefixMap}

  def build(repo, commit) do
    {:ok,
     """
     #{[:og] |> Ontogen.NS.prefixes() |> PrefixMap.to_sparql()}
     DELETE DATA {
       #{head(repo, commit.parent)}
       #{dataset_changes(repo, commit.remove)}
       #{dataset_changes(repo, commit.overwrite)}
     } ;
     INSERT DATA {
       #{head(repo, commit.__id__)}
       #{dataset_changes(repo, commit.add)}
       #{dataset_changes(repo, commit.update)}
       #{dataset_changes(repo, commit.replace)}
       #{provenance(repo, commit)}
       #{provenance(repo, commit.speech_act)}
     }
     """}
  end

  defp head(_, nil), do: ""

  defp head(repo, head) do
    "GRAPH <#{Repository.graph_id(repo)}> { <#{repo.__id__}> og:head <#{head}> }"
  end

  defp dataset_changes(_, nil), do: ""

  defp dataset_changes(repo, proposition) do
    do_dataset_changes(repo, proposition |> Proposition.graph() |> triples())
  end

  defp do_dataset_changes(repo, data) do
    "GRAPH <#{Repository.dataset_graph_id(repo)}> { #{data} }"
  end

  defp provenance(_, nil), do: ""

  defp provenance(repo, element) do
    "GRAPH <#{Repository.prov_graph_id(repo)}> { #{element |> Grax.to_rdf!() |> triples()} }"
  end

  defp triples(nil), do: ""
  defp triples(data), do: NTriples.write_string!(data)
end
