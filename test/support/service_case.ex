defmodule Ontogen.ServiceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Ontogen.BogCase, async: false

      alias Ontogen.{Service, Store, Repository, Dataset}

      import unquote(__MODULE__)
      import Ontogen.TestFixtures

      setup :clean_service!
    end
  end

  alias Ontogen.Operations.CleanCommand

  def clean_service!(context) do
    config_opts = (context[:config] || []) |> Keyword.put(:log, false)
    {setup?, boot_opts} = Keyword.pop(config_opts, :setup, true)

    start_supervised({Ontogen, boot_opts})

    if setup?, do: Ontogen.setup!()

    if Map.get(context, :clean_dataset, true) do
      # We can not use Ontogen.clean_dataset!() here because `on_exit` runs in a
      # separate process after the test process has terminated. This means the
      # Ontogen GenServer started above with `start_supervised` is no longer.
      on_exit(fn ->
        with {:ok, service} <- Ontogen.Config.service() do
          case CleanCommand.call(service, :all) do
            {:ok, _service} -> :ok
            {:error, _} = error -> raise error
          end
        end
      end)
    end

    :ok
  end
end
