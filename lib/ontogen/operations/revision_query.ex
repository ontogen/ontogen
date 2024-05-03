defmodule Ontogen.Operations.RevisionQuery do
  @moduledoc """
  Returns the graph of descriptions of given set of resource in a specific revision.

  Note: In this early version this command only allows to fetch the latest revision.
  """

  use Ontogen.Query,
    params: [
      :resources
    ]

  alias Ontogen.{Store, Repository}

  import Ontogen.QueryUtils, only: [to_term: 1]

  api do
    def revision(resources, args \\ []) do
      resources
      |> RevisionQuery.new(args)
      |> RevisionQuery.__do_call__()
    end

    def revision!(resources, args \\ []), do: bang!(&revision/2, [resources, args])
  end

  def new(resources, _args \\ []) do
    {:ok,
     %__MODULE__{
       resources: resources |> List.wrap() |> Enum.map(&RDF.coerce_subject/1)
     }}
  end

  @impl true
  def call(%__MODULE__{} = query, store, repository) do
    dataset_id = Repository.dataset_graph_id(repository)

    Store.construct(store, dataset_id, query(query.resources), raw_mode: true)
  end

  defp query(resources) do
    """
    CONSTRUCT { ?s ?p ?o }
    WHERE
    {
      VALUES (?s) {
        #{Enum.map_join(resources, "\n", &"(#{to_term(&1)})")}
      }
      ?s ?p ?o .
    }
    """
  end
end
