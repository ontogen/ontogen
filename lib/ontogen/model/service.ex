defmodule Ontogen.Service do
  use DCATR.Service.Type
  use Mud.Referencable
  alias Ontogen.{Repository, Agent}
  alias Ontogen.NS.Og

  schema Og.Service < Gno.Service do
    # we're inheriting store from Gno.Service
    link repository: Og.serviceRepository(), type: Repository, required: true, depth: false

    link operator: Og.serviceOperator(), type: Agent, required: true

    link commit_operation: Gno.serviceCommitOperation(),
         type: Ontogen.CommitOperation,
         required: true

    field :status
  end

  @status ~w[not_setup ready]a

  def set_status(%__MODULE__{} = service, status) when status in @status do
    %__MODULE__{service | status: status}
  end

  def head_id(%__MODULE__{repository: repository}), do: Repository.head_id(repository)

  def set_head(%__MODULE__{} = service, commit) do
    with {:ok, repository} <- Repository.set_head(service.repository, commit) do
      {:ok, %__MODULE__{service | repository: repository}}
    end
  end

  def handle_sparql(operation, service, opts \\ []) do
    Gno.Service.handle_sparql(operation, service, opts)
  end
end
