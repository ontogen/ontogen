defmodule Ontogen.Service.Setup.Extension do
  @moduledoc """
  Ontogen-specific setup extension for `Gno.Service.Setup`.
  """

  use Gno.Service.Setup.Extension

  alias Ontogen.NS.Og
  alias Ontogen.Service
  alias Gno.Store.SPARQL.Operation

  @impl true
  def setup(service, _opts) do
    Service.set_head(service, :root)
  end

  @impl true
  def check_setup(service, _opts) do
    """
    #{RDF.prefix_map(og: Og) |> RDF.PrefixMap.to_sparql()}
    ASK {
      <#{service.repository.__id__}> og:repositoryDataset ?dataset .
    }
    """
    |> Operation.ask!()
    |> Gno.Service.handle_sparql(service, graph: :repo)
    |> case do
      {:ok, %SPARQL.Query.Result{results: true}} -> :ok
      {:ok, %SPARQL.Query.Result{results: false}} -> {:error, :repository_not_found}
      {:error, reason} -> {:error, {:query_failed, reason}}
    end
  end

  @impl true
  def validate(service, _opts) do
    """
    #{RDF.prefix_map(og: Og) |> RDF.PrefixMap.to_sparql()}
    ASK {
      <#{service.repository.__id__}> a og:Repository ;
                                       og:repositoryDataset ?dataset ;
                                       og:repositoryHistory ?history .
      ?dataset a og:Dataset .
      ?history a og:History .
    }
    """
    |> Operation.ask!()
    |> Gno.Service.handle_sparql(service, graph: :repo)
    |> case do
      {:ok, %SPARQL.Query.Result{results: true}} -> :ok
      {:ok, %SPARQL.Query.Result{results: false}} -> {:error, :invalid_repository_structure}
      {:error, reason} -> {:error, {:query_failed, reason}}
    end
  end
end
