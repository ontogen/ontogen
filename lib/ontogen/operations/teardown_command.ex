defmodule Ontogen.Operations.TeardownCommand do
  use Ontogen.Operation.Command

  alias Ontogen.Service
  alias Ontogen.Service.Setup.Extension

  api do
    def teardown do
      TeardownCommand.new()
      |> TeardownCommand.__do_call__()
    end

    def teardown!, do: bang!(&teardown/0, [])
  end

  def new(), do: {:ok, %__MODULE__{}}
  def new!(), do: bang!(&new/0, [])

  def call(%Service{} = service) do
    new!() |> call(service)
  end

  @impl true
  def call(%__MODULE__{}, service) do
    with :ok <- Gno.Service.Setup.teardown(service, extension: Extension) do
      {:ok, Service.set_status(service, :not_setup)}
    end
  end
end
