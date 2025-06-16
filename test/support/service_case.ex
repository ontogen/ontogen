defmodule Ontogen.ServiceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Ontogen.MudCase, async: false

      import unquote(__MODULE__)
      import Ontogen.TestFixtures

      setup :clean_service!
    end
  end

  alias Ontogen.Operations.{SetupCommand, TeardownCommand}

  def clean_service!(context) do
    config_opts = (context[:config] || []) |> Keyword.put(:log, false)
    {setup?, boot_opts} = Keyword.pop(config_opts, :setup, true)
    service = Ontogen.Manifest.service!()

    if setup?, do: SetupCommand.do_setup(service)

    start_supervised({Ontogen, boot_opts})

    if Map.get(context, :teardown, true) do
      # We can not use Ontogen.teardown!() here because `on_exit` runs in a
      # separate process after the test process has terminated. This means the
      # Ontogen GenServer started above with `start_supervised` is no longer.
      on_exit(fn ->
        case TeardownCommand.call(service) do
          {:ok, _service} -> :ok
          {:error, :not_setup} -> :ok
          {:error, _} = error -> raise error
        end
      end)
    end

    :ok
  end
end
