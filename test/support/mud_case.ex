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
    salt_base_path =
      "tmp/test/data/" <> _ =
      Mud.salt_base_path()

    File.rm_rf!(salt_base_path)

    Mud.create_salt_base_path()

    :ok
  end
end
