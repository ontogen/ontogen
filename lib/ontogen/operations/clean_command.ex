defmodule Ontogen.Operations.CleanCommand do
  use Ontogen.Command, params: [:graphs]

  alias Ontogen.Service

  api do
    def clean_dataset do
      CleanCommand.new(:all)
      |> CleanCommand.__do_call__()
    end

    def clean_dataset!, do: bang!(&clean_dataset/0, [])
  end

  def new(:all) do
    {:ok, %__MODULE__{graphs: :all}}
  end

  def new!(graphs), do: bang!(&new/1, [graphs])

  @impl true
  def call(%__MODULE__{}, service) do
    with :ok <- delete_all(service) do
      {:ok, Service.set_status(service, :not_setup)}
    end
  end

  defp delete_all(service) do
    Ontogen.Store.SPARQL.Operation.drop!()
    |> Service.handle_sparql(service, :all)
  end
end
