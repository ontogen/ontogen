defmodule Mix.Tasks.Og.Teardown do
  use Mix.Task

  @shortdoc "Removes the Ontogen repository from the configured store"

  def run(_args) do
    with :ok <- Mix.Tasks.Og.Setup.start_deps() do
      case Gno.Service.Setup.teardown(Ontogen.Manifest.service!()) do
        :ok -> Mix.Shell.IO.info("Ontogen repository torn down")
        {:error, errors} -> Mix.raise("teardown failed: #{inspect(errors)}")
      end
    end
  end
end
