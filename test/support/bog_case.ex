defmodule Ontogen.BogCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use OntogenCase, async: false

      alias Ontogen.Bog

      import unquote(__MODULE__)

      setup :clean_salts!
    end
  end

  def clean_salts!(_context) do
    salt_base_path =
      "tmp/test/data/" <> _ =
      Ontogen.Bog.salt_base_path()

    File.rm_rf!(salt_base_path)

    Ontogen.Bog.create_salt_base_path()

    :ok
  end
end
