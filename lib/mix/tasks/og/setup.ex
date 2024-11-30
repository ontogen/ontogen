defmodule Mix.Tasks.Og.Setup do
  use Mix.Task

  alias Ontogen.Operations.SetupCommand
  alias Ontogen.Repository.SetupError

  @shortdoc "Install the Ontogen repository on the configured store"

  @deps [:grax, :sparql_client]

  def run(_args) do
    with :ok <- start_deps() do
      Mud.setup()

      case SetupCommand.call(Ontogen.Config.service!()) do
        {:ok, _service} -> Mix.Shell.IO.info("Set up Ontogen repository")
        {:error, %SetupError{reason: reason}} -> Mix.raise("setup failed: #{reason}")
        {:error, %{__exception__: true} = e} -> Mix.raise(Exception.message(e))
        {:error, error} -> Mix.raise(inspect(error))
      end
    end
  end

  defp start_deps, do: Enum.each(@deps, &start_dep/1)

  defp start_dep(dep) do
    case Application.ensure_all_started(dep) do
      {:ok, _started_apps} -> :ok
      {:error, {app, reason}} -> Mix.raise("unable to start #{app}: #{inspect(reason)}")
    end
  end
end
