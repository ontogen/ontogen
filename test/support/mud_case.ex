defmodule Ontogen.MudCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use OntogenCase, async: false

      import unquote(__MODULE__)

      setup :clean_index!
      setup :clean_seeds!
    end
  end

  def clean_index!(_context) do
    :ok = Mud.Identity.Index.clear()
  end

  def clean_seeds!(_context) do
    seed_path = "tmp/test/data/" <> _ = Mud.Seed.Directory.path()

    File.rm_rf!(seed_path)

    Mud.Seed.Directory.setup()

    :ok
  end
end
