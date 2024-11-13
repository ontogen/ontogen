defmodule Ontogen.MudCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use OntogenCase, async: false

      import unquote(__MODULE__)

      setup :clean_salts!
    end
  end

  def clean_salts!(_context) do
    salt_path = "tmp/test/data/" <> _ = Mud.salt_path()

    File.rm_rf!(salt_path)

    Mud.create_salt_path()

    :ok
  end
end
