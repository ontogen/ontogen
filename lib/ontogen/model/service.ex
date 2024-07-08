defmodule Ontogen.Service do
  use Grax.Schema
  use Ontogen.Bog.Referencable
  alias Ontogen.{Repository, Store, Agent}

  alias Ontogen.NS.Og

  schema Og.Service do
    link repository: Og.serviceRepository(), type: Repository, required: true
    link store: Og.serviceStore(), type: Store, required: true
    link operator: Og.serviceOperator(), type: Agent, required: true

    field :status
  end

  @status ~w[not_setup ready]a

  def set_status(%__MODULE__{} = service, status) when status in @status do
    %__MODULE__{service | status: status}
  end

  def set_head(%__MODULE__{} = service, commit) do
    with {:ok, repository} <- Repository.set_head(service.repository, commit) do
      {:ok, %__MODULE__{service | repository: repository}}
    end
  end

  def handle_sparql(operation, %__MODULE__{} = service, graph, opts \\ []) do
    Store.handle_sparql(operation, service.store, graph_name(service, graph), opts)
  end

  defp graph_name(_service, nil), do: nil
  defp graph_name(_service, :all), do: :all
  defp graph_name(_service, %RDF.IRI{} = graph_name), do: graph_name
  defp graph_name(service, :repo), do: Repository.graph_id(service.repository)
  defp graph_name(service, :dataset), do: Repository.dataset_graph_id(service.repository)
  defp graph_name(service, :prov), do: Repository.prov_graph_id(service.repository)
end
