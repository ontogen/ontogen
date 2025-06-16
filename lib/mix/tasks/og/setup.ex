defmodule Mix.Tasks.Og.Setup do
  use Mix.Task

  alias Ontogen.Operations.SetupCommand

  @shortdoc "Install the Ontogen repository on the configured store"

  @deps [:grax, :sparql_client, :mud, :gno]

  @switches [
    on_existing_dataset: :string,
    db_type: :string
  ]

  def run(args) do
    with :ok <- start_deps() do
      {opts, _args} = OptionParser.parse!(args, switches: @switches)
      setup_opts = Mix.Tasks.Gno.Setup.build_setup_opts(opts)

      Mud.setup()

      case SetupCommand.do_setup(Ontogen.Manifest.service!(), setup_opts) do
        {:ok, _service} -> Mix.Shell.IO.info("Set up Ontogen repository")
        {:error, %{__exception__: true} = e} -> Mix.raise("setup failed: #{Exception.message(e)}")
        {:error, error} -> Mix.raise("setup failed: #{inspect(error)}")
      end
    end
  end

  @doc false
  def start_deps, do: Enum.each(@deps, &start_dep/1)

  def start_dep(dep) do
    case Application.ensure_all_started(dep) do
      {:ok, _started_apps} -> :ok
      {:error, {app, reason}} -> Mix.raise("unable to start #{app}: #{inspect(reason)}")
    end
  end
end
