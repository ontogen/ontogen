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

  alias RDF.Graph

  def clean_index!(_context) do
    :ok = Mud.Identity.Index.clear()
  end

  def clean_seeds!(_context) do
    seed_path = "tmp/test/data/" <> _ = Mud.Seed.Directory.path()

    File.rm_rf!(seed_path)

    Mud.Seed.Directory.setup()

    :ok
  end

  def configured_store_adapter do
    "config/ontogen/test/service.ttl"
    |> RDF.read_file!()
    |> Graph.query([
      {:_service, Gno.serviceStore(), :_store},
      {:_store, Mud.this(), :store_adapter_class?}
    ])
    |> case do
      [%{store_adapter_class: store_adapter_class}] ->
        Grax.schema(store_adapter_class)
    end
  end
end
