defmodule Ontogen.Commands.Commit.Update do
  alias Ontogen.{Expression, Repository}
  alias Ontogen.NS.Og
  alias RDF.NTriples

  def build(_, :no_effective_changes, nil) do
    {:error, :no_effective_changes}
  end

  def build(repo, :no_effective_changes, utterance) do
    {:ok,
     """
     PREFIX og: <#{Og.__base_iri__()}>
     INSERT DATA {
       #{provenance(repo, utterance)}
     }
     """}
  end

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
       #{dataset_changes(repo, commit.update)}
       #{dataset_changes(repo, commit.replacement)}
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
  defp dataset_changes(_, []), do: ""

  defp dataset_changes(repo, [expression]), do: dataset_changes(repo, expression)

  defp dataset_changes(repo, expressions) when is_list(expressions) do
    do_dataset_changes(
      repo,
      Enum.map_join(expressions, "\n", &triples(Expression.graph(&1)))
    )
  end

  defp dataset_changes(repo, expression) do
    do_dataset_changes(repo, expression |> Expression.graph() |> triples())
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
