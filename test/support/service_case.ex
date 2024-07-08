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

  def clean_service!(context) do
    config_opts = (context[:config] || []) |> Keyword.put(:log, false)
    {setup?, boot_opts} = Keyword.pop(config_opts, :setup, true)

    start_supervised({Ontogen, boot_opts})

    if Ontogen.status() == :ready do
      Ontogen.clean_dataset!()
    end

    if setup?, do: Ontogen.setup!()

    :ok
  end
end
