defmodule Ontogen.Operations.SetupCommand do
  use Ontogen.Operation.Command, params: [opts: []]

  alias Ontogen.Service
  alias Ontogen.Operations.BootCommand
  alias Ontogen.Service.Setup.Extension

  require Logger

  api do
    def setup(opts \\ []) do
      SetupCommand.new(opts)
      |> SetupCommand.__do_call__()
    end

    def setup!(opts \\ []), do: bang!(&setup/1, [opts])
  end

  def new(opts \\ []), do: {:ok, new!(opts)}
  def new!(opts \\ []), do: %__MODULE__{opts: opts}

  def call(%Service{} = service) do
    new!() |> call(service)
  end

  @impl true
  def call(%__MODULE__{opts: opts}, service) do
    with {:ok, service} <- do_setup(service, opts) do
      BootCommand.new!(log: false) |> BootCommand.call(service)
    end
  end

  def do_setup(service, opts \\ []) do
    Gno.Service.Setup.setup(service, Keyword.put(opts, :extension, Extension))
  end
end
